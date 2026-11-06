// summary.md: what the maintainer reads after a run, in the spec's order.
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

export function renderSummary(s: RunSummaryInput): string {
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

  return `# fab run: ${s.project} on ${s.branch}

Spec \`${s.spec}\`, worktree \`${s.worktree}\`.

## Shipped

${list(shipped, "nothing")}

## Decisions taken

${list(decisions)}

## Dependencies added

${list(dependencies)}

## Files deleted

${list(deleted)}

## Parked questions

${list(parkedQuestions)}

## Failures

${list(failures)}

## How to try it

${list(demos, "no demo reported")}

## Next task

${s.nextTask ?? "none open"}

## Run

- Started ${s.startedAt}, ended ${s.endedAt}, ${minutes(s.startedAt, s.endedAt)} min.
- Tasks: ${done.length} done, ${parked.length} parked, ${failed.length} failed.
- Stopped because: ${s.stopReason}.
- Push: ${typeof s.pushed === "boolean" ? (s.pushed ? "pushed" : "not pushed") : s.pushed}.
`;
}
