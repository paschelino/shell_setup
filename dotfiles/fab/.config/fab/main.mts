// fab's orchestrator: one sandcastle run() per open task of the spec's Tasks
// table, until the queue is empty, the deadline has passed or two tasks in a
// row failed. Started by the `fab` command with a run directory holding
// run.json. Reports through `mx`, never through an agent.
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import {
  run,
  claudeCode,
  opencode,
  Output,
  StructuredOutputError,
  type AgentProvider,
} from "@ai-hero/sandcastle";
import { seatbelt } from "@ai-hero/sandcastle/sandboxes/seatbelt";
import {
  readTasks,
  readyTasks,
  blockedTasks,
  checkSelection,
  type Task,
} from "./lib/tasks.mts";
import { Reporter } from "./lib/status.mts";
import { taskReport, REPORT_TAG, type TaskReport } from "./lib/report.mts";
import { renderSummary, type TaskOutcome } from "./lib/summary.mts";
import {
  readDotenv,
  readGlobalInstructions,
  readMounts,
  readSandboxEnv,
  type Mount,
} from "./lib/env.mts";
import { updateRun } from "./lib/runs.mts";

interface RunConfig {
  id: string;
  project: string;
  projectDir: string;
  worktree: string;
  branch: string;
  spec: string; // relative to the worktree
  agent: "claude" | "opencode" | "fake";
  model: string;
  until: string; // ISO
  onlyTasks?: string[]; // --task: the queue is restricted to these rows
  idleSeconds?: number; // --idle: sandcastle fails a task silent this long
  push: boolean;
  startedAt: string;
  pid: number;
}

// With --preserve-symlinks this is ~/.config/fab even when main.mts is a
// stow link into the repository, which is where node_modules and .env live.
const CONFIG_DIR = dirname(fileURLToPath(import.meta.url));
const MAX_CONSECUTIVE_FAILURES = 2;
// A browser gate inside one tool call can be silent for most of an hour.
const DEFAULT_IDLE_SECONDS = 3600;

const runDir = process.argv[2];
if (!runDir || !existsSync(join(runDir, "run.json"))) {
  console.error("usage: main.mts <run-dir with run.json>");
  process.exit(64);
}
const cfg: RunConfig = JSON.parse(
  readFileSync(join(runDir, "run.json"), "utf8"),
);
const specPath = join(cfg.worktree, cfg.spec);
const specDir = dirname(specPath);
const label = `fab ${cfg.project}`;
const reporter = new Reporter(join(runDir, "events.jsonl"), label);
const dotenv = readDotenv(join(CONFIG_DIR, ".env"));

// The sandbox allows writes only in the worktree and its private $TMPDIR, but
// Claude Code keeps scratch files under /tmp/claude-<uid> (EPERM at start) and
// zsh, the agent's Bash tool shell, writes heredoc temp files under /tmp/zsh.
// The agent command runs through /bin/sh, so $TMPDIR expands inside the
// sandbox; both tools create what they need under it.
function withSandboxTmp(inner: AgentProvider): AgentProvider {
  return {
    ...inner,
    buildPrintCommand: (o) => {
      const c = inner.buildPrintCommand(o);
      return {
        ...c,
        command: `CLAUDE_CODE_TMPDIR="$TMPDIR/claude" TMPPREFIX="$TMPDIR/zsh" ${c.command}`,
      };
    },
  };
}

function agentProvider(): AgentProvider {
  const pick = (...keys: string[]) =>
    Object.fromEntries(
      keys.filter((k) => dotenv[k]).map((k) => [k, dotenv[k]]),
    );
  switch (cfg.agent) {
    case "claude":
      return withSandboxTmp(
        claudeCode(cfg.model, {
          env: pick("CLAUDE_CODE_OAUTH_TOKEN", "ANTHROPIC_API_KEY"),
        }),
      );
    case "opencode":
      return withSandboxTmp(
        opencode(cfg.model, { env: pick(...Object.keys(dotenv)) }),
      );
    case "fake": {
      // Test hook: FAB_FAKE_AGENT names a script that gets the prompt on stdin
      // and plays the agent. Never used for real work.
      const script = process.env.FAB_FAKE_AGENT;
      if (!script) throw new Error("agent fake needs FAB_FAKE_AGENT=<script>");
      // The sandbox hides the home directory, so the script's text travels in
      // the command itself rather than as a path.
      const body = readFileSync(script, "utf8").replace(/'/g, "'\\''");
      return {
        name: "fake",
        env: Object.fromEntries(
          Object.entries(process.env).filter(([k]) =>
            k.startsWith("FAB_FAKE_"),
          ) as [string, string][],
        ),
        captureSessions: false,
        buildPrintCommand: ({ prompt }) => ({
          command: `sh -c '${body}'`,
          stdin: prompt,
        }),
        parseStreamLine: (line) => [{ type: "text", text: `${line}\n` }],
      };
    }
  }
}

function relOrNone(path: string): string {
  return existsSync(path) ? relative(cfg.worktree, path) : "none";
}

function promptArgs(task: Task): Record<string, string> {
  const until = new Date(cfg.until);
  return {
    PROJECT: cfg.project,
    BRANCH: cfg.branch,
    SPEC_PATH: cfg.spec,
    RUN_BRIEF_PATH: relOrNone(join(specDir, "run-brief.md")),
    PROGRESS_PATH: relOrNone(join(specDir, "progress.md")),
    TASK_ID: task.id,
    TASK_STEP: task.step,
    TASK_DONE_WHEN: task.doneWhen || "see the spec's acceptance criteria",
    TASK_DEMO: task.demo || "describe how to see the result",
    DATE: new Date().toISOString().slice(0, 10),
    DEADLINE: `${until.toISOString()} (${Math.max(0, Math.round((until.getTime() - Date.now()) / 60_000))} minutes from now)`,
    GLOBAL_INSTRUCTIONS: readGlobalInstructions() || "(none found)",
  };
}

function git(args: string[]): string {
  return execFileSync("git", ["-C", cfg.worktree, ...args], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  }).trim();
}

type PushResult = "pushed" | "no remote" | "no commits" | "disabled" | "failed";

function pushIfAllowed(outcomes: TaskOutcome[]): PushResult {
  if (!cfg.push) return "disabled";
  if (!git(["remote"])) return "no remote";
  if (!outcomes.some((o) => o.commits.length)) return "no commits";
  try {
    git(["push", "-u", "origin", cfg.branch]);
    return "pushed";
  } catch (e) {
    reporter.event("push.failed", { error: String(e) });
    return "failed";
  }
}

async function runTask(
  task: Task,
  agent: AgentProvider,
  mounts: Mount[],
  sandboxEnv: Record<string, string>,
): Promise<TaskOutcome> {
  const startedAt = new Date().toISOString();
  reporter.event("task.start", { task: task.id, step: task.step });
  reporter.state("working", `${task.id} ${task.step.slice(0, 60)}`);
  console.log(`[${label}] ${task.id}: ${task.step.slice(0, 100)}`);
  let report: TaskReport | null = null;
  let commits: string[] = [];
  let error: string | undefined;
  try {
    const result = await run({
      agent,
      sandbox: seatbelt({ mounts, env: sandboxEnv }),
      cwd: cfg.worktree,
      branchStrategy: { type: "head" },
      promptFile: join(CONFIG_DIR, "prompts", "task.md"),
      promptArgs: promptArgs(task),
      maxIterations: 1,
      idleTimeoutSeconds: cfg.idleSeconds ?? DEFAULT_IDLE_SECONDS,
      name: `${cfg.project} ${task.id}`,
      logging: { type: "file", path: join(runDir, "sandcastle.log") },
      output: Output.object({
        tag: REPORT_TAG,
        schema: taskReport,
        maxRetries: cfg.agent === "fake" ? 0 : 1,
      }),
    });
    report = result.output;
    commits = result.commits.map((c) => c.sha);
  } catch (e) {
    error = e instanceof Error ? e.message : String(e);
    if (e instanceof StructuredOutputError)
      commits = e.commits.map((c) => c.sha);
  }
  const endedAt = new Date().toISOString();
  reporter.event("task.end", {
    task: task.id,
    status: report?.status ?? "error",
    commits,
    error,
    report,
  });
  console.log(
    `[${label}] ${task.id}: ${report?.status ?? "error"}${error ? ` (${error.split("\n")[0]})` : ""}`,
  );
  return { task: task.id, report, commits, error, startedAt, endedAt };
}

async function main() {
  const agent = agentProvider();
  const mounts = readMounts(CONFIG_DIR);
  const sandboxEnv = readSandboxEnv(CONFIG_DIR);
  const only = cfg.onlyTasks?.length ? new Set(cfg.onlyTasks) : undefined;
  if (only) {
    const { unknown, done } = checkSelection(readTasks(specPath), [...only]);
    if (unknown.length) {
      const msg = `--task names no row of ${cfg.spec}: ${unknown.join(", ")}`;
      reporter.event("run.refused", { error: msg });
      updateRun(runDir, {
        endedAt: new Date().toISOString(),
        stopReason: `refused: ${msg}`,
        tasks: 0,
      });
      console.error(`fab: ${msg}`);
      process.exitCode = 2;
      return;
    }
    if (done.length)
      console.log(`[${label}] already done, skipped: ${done.join(", ")}`);
  }
  const deadline = new Date(cfg.until).getTime();
  const completed = new Set<string>(); // done in this run: satisfies dependencies
  const attempted = new Set<string>(); // done, parked or failed: not offered again
  const outcomes: TaskOutcome[] = [];
  let consecutiveFailures = 0;
  let stopReason = "queue empty";

  reporter.event("run.start", {
    ...cfg,
    mounts: mounts.map((m) => `${m.hostPath}${m.readonly ? "" : " rw"}`),
    sandboxEnv: Object.keys(sandboxEnv),
  });
  reporter.state("working", `starting on ${cfg.branch}`);

  for (;;) {
    if (Date.now() >= deadline) {
      stopReason = `deadline ${cfg.until}`;
      break;
    }
    if (consecutiveFailures >= MAX_CONSECUTIVE_FAILURES) {
      stopReason = `${MAX_CONSECUTIVE_FAILURES} tasks in a row failed`;
      break;
    }
    const tasks = readTasks(specPath);
    const ready = readyTasks(tasks, completed, attempted, only);
    if (ready.length === 0) {
      const blocked = blockedTasks(tasks, completed, attempted, only);
      if (blocked.length) stopReason = `queue empty; ${blocked.join("; ")}`;
      break;
    }
    const task = ready[0];
    const outcome = await runTask(task, agent, mounts, sandboxEnv);
    outcomes.push(outcome);
    // A task is not retried in the same run, whatever happened to it.
    attempted.add(task.id);
    if (outcome.report?.status === "done") completed.add(task.id);
    const failed =
      outcome.error !== undefined || outcome.report?.status === "failed";
    consecutiveFailures = failed ? consecutiveFailures + 1 : 0;
  }

  const pushed = pushIfAllowed(outcomes);
  const endedAt = new Date().toISOString();
  // For the maintainer, a parked or failed task is still the next thing to
  // look at, and the next task is the whole table's, not just --task's.
  const nextTask = readyTasks(readTasks(specPath), completed)[0]?.id ?? null;
  const summary = renderSummary(
    {
      project: cfg.project,
      branch: cfg.branch,
      worktree: cfg.worktree,
      spec: cfg.spec,
      startedAt: cfg.startedAt,
      endedAt,
      stopReason,
      outcomes,
      nextTask,
      pushed,
    },
    join(CONFIG_DIR, "prompts", "summary.md"),
  );
  writeFileSync(join(runDir, "summary.md"), summary);
  const done = outcomes.filter((o) => o.report?.status === "done").length;
  const parked = outcomes.filter((o) => o.report?.status === "parked").length;
  const failed = outcomes.length - done - parked;
  updateRun(runDir, {
    endedAt,
    stopReason,
    pushed,
    tasks: outcomes.length,
    done,
    parked,
    failed,
    nextTask,
  });
  reporter.event("run.end", {
    stopReason,
    pushed,
    tasks: outcomes.length,
    nextTask,
  });

  const headline = `${done} done, ${parked} parked, ${failed} failed; stopped: ${stopReason}`;
  reporter.notify(label, `${headline}. Summary: ${join(runDir, "summary.md")}`);
  reporter.state(failed && !done ? "error" : "done", headline);
  console.log(`[${label}] ${headline}`);
  console.log(`[${label}] summary: ${join(runDir, "summary.md")}`);
  process.exitCode = failed && !done ? 1 : 0;
}

main().catch((e) => {
  reporter.event("run.crash", { error: String(e) });
  reporter.state("error", String(e).split("\n")[0].slice(0, 80));
  console.error(`[${label}] crashed:`, e);
  process.exitCode = 1;
});
