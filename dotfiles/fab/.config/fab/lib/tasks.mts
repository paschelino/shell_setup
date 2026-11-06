// The spec's Tasks table is the queue. Columns, in order: Task, Step,
// Depends on, Done when, Demo. The older shape Task, Step, Covers is accepted
// too: then nothing depends on anything and order decides.
import { readFileSync } from "node:fs";

export interface Task {
  id: string;
  step: string;
  dependsOn: string[];
  doneWhen: string;
  demo: string;
  done: boolean;
}

const cell = (s: string) => s.trim();

// A task is done when its Step cell starts with **Done, as in `**Done** 2026-…`
// or the older `**Done: …**`.
const isDone = (step: string) => /^\*\*Done\b/i.test(step.trim());

export function parseTasks(markdown: string): Task[] {
  const lines = markdown.split("\n");
  const start = lines.findIndex((l) => /^##\s+Tasks\b/.test(l));
  if (start < 0) return [];
  const rows: string[][] = [];
  for (let i = start + 1; i < lines.length; i++) {
    const line = lines[i];
    if (/^##\s/.test(line)) break;
    if (!line.trim().startsWith("|")) continue;
    const cells = line.trim().slice(1, -1).split("|").map(cell);
    rows.push(cells);
  }
  if (rows.length < 2) return [];
  const header = rows[0].map((h) => h.toLowerCase());
  const col = (name: string) => header.findIndex((h) => h === name);
  const iTask = col("task");
  const iStep = col("step");
  const iDeps = col("depends on");
  const iDone = col("done when");
  const iDemo = col("demo");
  if (iTask < 0 || iStep < 0) return [];
  return rows
    .slice(1)
    .filter((r) => !/^-+$/.test(r[iTask] ?? "") && (r[iTask] ?? "") !== "")
    .map((r) => {
      const deps = iDeps >= 0 ? (r[iDeps] ?? "") : "";
      return {
        id: r[iTask],
        step: r[iStep] ?? "",
        dependsOn: deps
          .split(",")
          .map((d) => d.trim())
          .filter((d) => d && d !== "-"),
        doneWhen: iDone >= 0 ? (r[iDone] ?? "") : "",
        demo: iDemo >= 0 ? (r[iDemo] ?? "") : "",
        done: isDone(r[iStep] ?? ""),
      };
    });
}

export function readTasks(specPath: string): Task[] {
  return parseTasks(readFileSync(specPath, "utf8"));
}

// Open tasks whose dependencies are all done, in table order. `completed` are
// the ids this run finished successfully, whether or not the agent marked the
// row; `skip` are ids not to offer again, such as parked or failed ones. A
// parked task is not done, so what depends on it waits.
export function readyTasks(
  tasks: Task[],
  completed: Set<string>,
  skip: Set<string> = completed,
): Task[] {
  const done = (id: string) =>
    completed.has(id) || tasks.some((t) => t.id === id && t.done);
  return tasks.filter(
    (t) =>
      !t.done &&
      !completed.has(t.id) &&
      !skip.has(t.id) &&
      t.dependsOn.every(done),
  );
}
