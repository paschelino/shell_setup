// fab tail: a run's events and the agent's text as readable lines, followed
// until the run ends. Meant for a multiplexer pane beside the work.
import { closeSync, existsSync, openSync, readSync, statSync } from "node:fs";
import { StringDecoder } from "node:string_decoder";
import { join } from "node:path";
import { styleText } from "node:util";
import { readRun, runState } from "./runs.mts";

const POLL_MS = 500;
const MAX_LINE = 400;

// Reads what was appended to a file since the last call, as whole lines.
class Follower {
  readonly path: string;
  private offset = 0;
  private partial = "";
  private decoder = new StringDecoder("utf8");

  constructor(path: string) {
    this.path = path;
  }

  lines(): string[] {
    if (!existsSync(this.path)) return [];
    const size = statSync(this.path).size;
    if (size < this.offset) this.offset = 0; // truncated or replaced
    if (size === this.offset) return [];
    const buf = Buffer.alloc(size - this.offset);
    const fd = openSync(this.path, "r");
    try {
      readSync(fd, buf, 0, buf.length, this.offset);
    } finally {
      closeSync(fd);
    }
    this.offset = size;
    const text = this.partial + this.decoder.write(buf);
    const parts = text.split("\n");
    this.partial = parts.pop() ?? "";
    return parts;
  }

  rest(): string[] {
    const last = this.partial + this.decoder.end();
    this.partial = "";
    return last ? [last] : [];
  }
}

const clock = (iso: unknown) =>
  typeof iso === "string"
    ? new Date(iso).toLocaleTimeString("en-GB", { hour12: false })
    : "--:--:--";

const firstLine = (s: unknown, max = 160) =>
  String(s ?? "")
    .split("\n")[0]
    .slice(0, max);

const bold = (s: string) => styleText("bold", s);

// One events.jsonl line as one or more readable lines.
export function formatEvent(line: string): string[] {
  if (!line.trim()) return [];
  let e: Record<string, any>;
  try {
    e = JSON.parse(line);
  } catch {
    return [line];
  }
  const t = clock(e.at);
  switch (e.type) {
    case "run.start":
      return [
        bold(
          `${t} run ${e.id}: ${e.branch}, ${e.agent} (${e.model}), until ${clock(e.until)}` +
            (e.onlyTasks?.length ? `, tasks ${e.onlyTasks.join(",")}` : ""),
        ),
      ];
    case "task.start":
      return [bold(`${t} ▶ ${e.task} ${firstLine(e.step, 120)}`)];
    case "task.end": {
      const commits = e.commits?.length ?? 0;
      const out = [
        bold(
          `${t} ■ ${e.task} ${e.status}` +
            (commits ? `, ${commits} commit${commits > 1 ? "s" : ""}` : "") +
            (e.error ? `: ${firstLine(e.error)}` : ""),
        ),
      ];
      if (e.report?.summary)
        out.push(`         ${firstLine(e.report.summary, 300)}`);
      for (const p of e.report?.parked ?? [])
        out.push(`         parked: ${firstLine(p.question, 300)}`);
      return out;
    }
    case "run.end":
      return [
        bold(
          `${t} run ended: ${e.stopReason}; push: ${e.pushed}; next: ${e.nextTask ?? "none"}`,
        ),
      ];
    default:
      return [`${t} ${e.type}${e.error ? `: ${firstLine(e.error)}` : ""}`];
  }
}

// sandcastle's own lines around each task, which the events already say.
const BOILERPLATE = [
  /^--- Run started: .* ---$/,
  /^Sandcastle Run$/,
  /^ {2}(Agent|Sandbox|Max iterations|Branch): /,
  /^Iteration \d+\/\d+$/,
  /^(Setting up sandbox|Collecting commits)(\.\.\.| done \(.*\))?$/,
  /^Agent (started|stopped)$/,
  /^Reached max iterations/,
  /^Run complete: /,
];

// One sandcastle.log line: the agent's text and tool calls, indented and
// dimmed under the events, colour codes stripped, very long lines cut.
export function formatLog(line: string): string[] {
  // eslint-disable-next-line no-control-regex
  const plain = line.replace(/\x1b\[[0-9;]*m/g, "").trimEnd();
  if (!plain.trim() || BOILERPLATE.some((re) => re.test(plain))) return [];
  const cut = plain.length > MAX_LINE ? `${plain.slice(0, MAX_LINE)}…` : plain;
  return [styleText("dim", `  ${cut}`)];
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

// Prints the run's events and the last `backlog` log lines, then follows both
// files until the run has ended or its process is gone.
export async function tail(
  dir: string,
  opts: { backlog: number; follow: boolean },
): Promise<void> {
  const events = new Follower(join(dir, "events.jsonl"));
  const log = new Follower(join(dir, "sandcastle.log"));
  const out = (lines: string[]) =>
    lines.length && console.log(lines.join("\n"));
  const run = readRun(dir);
  out([bold(`fab tail ${run.id} (${runState(run)})`)]);

  out(events.lines().flatMap(formatEvent));
  const earlier = log.lines().flatMap(formatLog);
  const skipped = Math.max(0, earlier.length - opts.backlog);
  if (skipped)
    out([styleText("dim", `  … ${skipped} earlier lines in ${log.path}`)]);
  out(earlier.slice(skipped));

  for (let state = runState(run); opts.follow && state === "running";) {
    await sleep(POLL_MS);
    state = runState(readRun(dir));
    out(log.lines().flatMap(formatLog));
    out(events.lines().flatMap(formatEvent));
    if (state === "crashed")
      out([bold("fab: the run's process is gone without an end")]);
  }
  out(log.rest().flatMap(formatLog));
  out(events.rest().flatMap(formatEvent));
}
