// The runs under ~/.local/state/fab/runs/: finding one, reading and updating
// its run.json, the review stamps and the `fab runs` table.
import {
  existsSync,
  readFileSync,
  readdirSync,
  renameSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

export interface Review {
  startedAt: string;
  endedAt?: string;
  note?: string;
}

// run.json as the `fab` command writes it and main.mts completes it.
export interface RunRecord {
  id: string;
  project: string;
  branch: string;
  spec: string;
  startedAt: string;
  pid: number;
  onlyTasks?: string[];
  endedAt?: string;
  stopReason?: string;
  tasks?: number;
  done?: number;
  parked?: number;
  failed?: number;
  reviews?: Review[];
  [key: string]: unknown;
}

export const runsDir = () =>
  join(
    process.env.XDG_STATE_HOME || join(homedir(), ".local", "state"),
    "fab",
    "runs",
  );

// Run ids end in -YYYYMMDD-HHMMSS; sort on that, not on the project name.
const stamp = (id: string) => id.slice(-15);

export function listRunIds(): string[] {
  const dir = runsDir();
  if (!existsSync(dir)) return [];
  return readdirSync(dir, { withFileTypes: true })
    .filter((e) => e.isDirectory() && existsSync(join(dir, e.name, "run.json")))
    .map((e) => e.name)
    .sort((a, b) => stamp(b).localeCompare(stamp(a)));
}

// The run directory for an id, or the newest run's when none is given.
export function resolveRun(id?: string): string {
  if (id) {
    const dir = join(runsDir(), id);
    if (!existsSync(join(dir, "run.json"))) throw new Error(`no run ${id}`);
    return dir;
  }
  const newest = listRunIds()[0];
  if (!newest) throw new Error("no runs yet");
  return join(runsDir(), newest);
}

export function readRun(dir: string): RunRecord {
  return JSON.parse(readFileSync(join(dir, "run.json"), "utf8"));
}

// Merges fields into run.json, re-reading it first so the runner's and a
// review's writes don't overwrite each other; the rename makes it atomic.
export function updateRun(dir: string, patch: Partial<RunRecord>): RunRecord {
  const run = { ...readRun(dir), ...patch };
  const tmp = join(dir, `.run.json.${process.pid}`);
  writeFileSync(tmp, JSON.stringify(run, null, 2) + "\n");
  renameSync(tmp, join(dir, "run.json"));
  return run;
}

export function isAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch (e) {
    return (e as NodeJS.ErrnoException).code === "EPERM";
  }
}

export const runState = (r: RunRecord) =>
  r.endedAt ? "ended" : isAlive(r.pid) ? "running" : "crashed";

const minutesBetween = (a: string, b: string) =>
  (new Date(b).getTime() - new Date(a).getTime()) / 60_000;

// Minutes spent in finished reviews, summed; null when none finished.
export function reviewMinutes(r: RunRecord): number | null {
  const closed = (r.reviews ?? []).filter((v) => v.endedAt);
  if (!closed.length) return null;
  return closed.reduce(
    (m, v) => m + minutesBetween(v.startedAt, v.endedAt!),
    0,
  );
}

export const openReview = (r: RunRecord) =>
  (r.reviews ?? []).find((v) => !v.endedAt);

// Starts a review of the run unless one is open; returns the open review.
export function startReview(dir: string): { review: Review; resumed: boolean } {
  const run = readRun(dir);
  const open = openReview(run);
  if (open) return { review: open, resumed: true };
  const review = { startedAt: new Date().toISOString() };
  updateRun(dir, { reviews: [...(run.reviews ?? []), review] });
  return { review, resumed: false };
}

// Ends the most recently started open review over all runs.
export function endReview(note?: string): { id: string; minutes: number } {
  let latest: { dir: string; started: string } | null = null;
  for (const id of listRunIds()) {
    const dir = join(runsDir(), id);
    const open = openReview(readRun(dir));
    if (open && (!latest || open.startedAt > latest.started))
      latest = { dir, started: open.startedAt };
  }
  if (!latest)
    throw new Error("no review is open; start one with `fab review`");
  const run = readRun(latest.dir);
  const endedAt = new Date().toISOString();
  const reviews = (run.reviews ?? []).map((v) =>
    v.endedAt ? v : { ...v, endedAt, ...(note ? { note } : {}) },
  );
  updateRun(latest.dir, { reviews });
  return { id: run.id, minutes: minutesBetween(latest.started, endedAt) };
}

const fmtMinutes = (m: number) => {
  const total = Math.round(m);
  return total < 60
    ? `${total}m`
    : `${Math.floor(total / 60)}h${String(total % 60).padStart(2, "0")}m`;
};

// The `fab runs` table, newest first.
export function runsTable(): string {
  const rows = listRunIds().map((id) => {
    const r = readRun(join(runsDir(), id));
    const state = runState(r);
    const tasks =
      r.tasks === undefined
        ? "-"
        : r.done === undefined
          ? String(r.tasks)
          : `${r.done}/${r.parked}/${r.failed}`;
    const ran = fmtMinutes(
      minutesBetween(r.startedAt, r.endedAt ?? new Date().toISOString()),
    );
    const reviewed = reviewMinutes(r);
    const review = openReview(r)
      ? "open"
      : reviewed === null
        ? "-"
        : fmtMinutes(reviewed);
    const stop = state === "ended" ? (r.stopReason ?? "") : state;
    return [id, tasks, ran, review, stop];
  });
  if (!rows.length) return "no runs yet";
  const header = ["RUN", "DONE/PARKED/FAILED", "RAN", "REVIEW", "STOP"];
  const all = [header, ...rows];
  const widths = header.map((_, i) => Math.max(...all.map((r) => r[i].length)));
  return all
    .map((r) =>
      r
        .map((c, i) => (i === r.length - 1 ? c : c.padEnd(widths[i])))
        .join("  "),
    )
    .join("\n");
}
