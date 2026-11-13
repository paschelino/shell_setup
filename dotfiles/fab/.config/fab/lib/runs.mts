// The runs under ~/.local/state/fab/runs/: reading and updating a run's
// run.json.
import { readFileSync, renameSync, writeFileSync } from "node:fs";
import { join } from "node:path";

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
  [key: string]: unknown;
}

export function readRun(dir: string): RunRecord {
  return JSON.parse(readFileSync(join(dir, "run.json"), "utf8"));
}

// Merges fields into run.json, re-reading it first so the runner's and other
// writes don't overwrite each other; the rename makes it atomic.
export function updateRun(dir: string, patch: Partial<RunRecord>): RunRecord {
  const run = { ...readRun(dir), ...patch };
  const tmp = join(dir, `.run.json.${process.pid}`);
  writeFileSync(tmp, JSON.stringify(run, null, 2) + "\n");
  renameSync(tmp, join(dir, "run.json"));
  return run;
}
