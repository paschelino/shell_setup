// summary.md: what the maintainer reads after a run, in the spec's order. The
// wording lives in prompts/summary.md; this file fills its {{KEY}} slots, with
// the lists already rendered.
import { readFileSync } from "node:fs";
import type { TaskReport } from "./report.mts";

export interface TaskOutcome {
  task: string;
  report: TaskReport | null;
  commits: string[];
  error?: string;
  startedAt: string;
  endedAt: string;
}

export interface RunSummaryInput {
  project: string;
  branch: string;
  worktree: string;
  spec: string;
  startedAt: string;
  endedAt: string;
  stopReason: string;
  outcomes: TaskOutcome[];
  nextTask: string | null;
  pushed: boolean | "no remote" | "no commits" | "disabled" | "failed";
}

const list = (items: string[], empty = "none") =>
  items.length ? items.map((i) => `- ${i}`).join("\n") : `- ${empty}`;

const minutes = (a: string, b: string) =>
  Math.round((new Date(b).getTime() - new Date(a).getTime()) / 60_000);

// {{KEY}} substitution as sandcastle does it for prompts: a slot without a
// value is a bug, not an empty string.
export function fillTemplate(
  template: string,
  values: Record<string, string>,
): string {
  return template.replace(/\{\{([A-Z_]+)\}\}/g, (_, key: string) => {
    if (!(key in values)) throw new Error(`summary template: no value for {{${key}}}`);
    return values[key];
  });
}

export function renderSummary(s: RunSummaryInput, templatePath: string): string {
  const reports = s.outcomes
    .map((o) => o.report)
    .filter((r): r is TaskReport => r !== null);
  const done = reports.filter((r) => r.status === "done");
  const parked = reports.filter((r) => r.status === "parked");
  const failed = s.outcomes.filter(
    (o) => o.error || o.report?.status === "failed",
  );
  const shipped = s.outcomes
    .filter((o) => o.report?.status === "done")
    .map(
      (o) =>
        `${o.report!.task}: ${o.report!.summary}${o.commits.length ? ` (${o.commits.map((c) => c.slice(0, 7)).join(", ")})` : ""}`,
    );
  const decisions = reports.flatMap((r) =>
    r.decisions.map((d) => `${r.task}: ${d}`),
  );
  const dependencies = reports.flatMap((r) =>
    r.dependencies.map((d) => `${r.task}: ${d}`),
  );
  const deleted = reports.flatMap((r) =>
    r.deleted.map((d) => `${r.task}: ${d}`),
  );
  const parkedQuestions = reports.flatMap((r) =>
    r.parked.map((p) => `${r.task}: ${p.question}\n  Assumed: ${p.assumption}`),
  );
  const demos = reports
    .filter((r) => r.demo)
    .map((r) => `${r.task}: ${r.demo}`);
  const failures = failed.map(
    (o) =>
      `${o.task}: ${(o.error ?? o.report?.summary ?? "failed").split("\n").slice(0, 3).join(" / ")}`,
  );

  return fillTemplate(readFileSync(templatePath, "utf8"), {
    PROJECT: s.project,
    BRANCH: s.branch,
    SPEC: s.spec,
    WORKTREE: s.worktree,
    SHIPPED: list(shipped, "nothing"),
    DECISIONS: list(decisions),
    DEPENDENCIES: list(dependencies),
    DELETED: list(deleted),
    PARKED: list(parkedQuestions),
    FAILURES: list(failures),
    DEMOS: list(demos, "no demo reported"),
    NEXT_TASK: s.nextTask ?? "none open",
    STARTED_AT: s.startedAt,
    ENDED_AT: s.endedAt,
    MINUTES: String(minutes(s.startedAt, s.endedAt)),
    DONE_COUNT: String(done.length),
    PARKED_COUNT: String(parked.length),
    FAILED_COUNT: String(failed.length),
    STOP_REASON: s.stopReason,
    PUSH:
      typeof s.pushed === "boolean"
        ? s.pushed
          ? "pushed"
          : "not pushed"
        : s.pushed,
  });
}
