// fab's verbs that read the run state: runs, review and tail. Started by the
// `fab` command; `fab run` goes to main.mts instead.
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import {
  endReview,
  readRun,
  resolveRun,
  runState,
  runsTable,
  startReview,
} from "./lib/runs.mts";
import { tail } from "./lib/tail.mts";

const clock = (iso: string) =>
  new Date(iso).toLocaleTimeString("en-GB", {
    hour: "2-digit",
    minute: "2-digit",
  });

// fab review [run-id]: the summary, and a review start stamp in run.json.
// fab review --done [note]: the end stamp on the latest open review.
function review(args: string[]) {
  if (args[0] === "--done") {
    const note = args.slice(1).join(" ").trim() || undefined;
    const { id, minutes } = endReview(note);
    console.log(
      `fab: review of ${id} ended after ${Math.round(minutes)} minutes`,
    );
    return;
  }
  if (args.length > 1 || args[0]?.startsWith("-"))
    throw new Error("usage: fab review [run-id] | fab review --done [note]");
  const dir = resolveRun(args[0]);
  const run = readRun(dir);
  const summary = join(dir, "summary.md");
  if (!existsSync(summary)) {
    const state = runState(run);
    throw new Error(
      state === "running"
        ? `run ${run.id} is still running; review it after it ends (fab tail ${run.id})`
        : `run ${run.id} has no summary (${state}); see fab tail ${run.id}`,
    );
  }
  process.stdout.write(readFileSync(summary, "utf8"));
  const { review, resumed } = startReview(dir);
  console.log(
    `\nfab: review of ${run.id} ${resumed ? "open since" : "started at"} ${clock(review.startedAt)}; ` +
      "end it with: fab review --done [note]",
  );
}

// fab tail [run-id] [-n <lines>] [--no-follow]
async function tailVerb(args: string[]) {
  let id: string | undefined;
  let backlog = 40;
  let follow = true;
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "-n") {
      backlog = Number(args[++i]);
      if (!Number.isInteger(backlog) || backlog < 0)
        throw new Error("-n needs a number of lines");
    } else if (a === "--no-follow") follow = false;
    else if (a.startsWith("-")) throw new Error(`unknown option ${a}`);
    else if (id)
      throw new Error("usage: fab tail [run-id] [-n <lines>] [--no-follow]");
    else id = a;
  }
  await tail(resolveRun(id), { backlog, follow });
}

async function main(verb: string, args: string[]) {
  switch (verb) {
    case "runs":
      console.log(runsTable());
      return;
    case "review":
      return review(args);
    case "tail":
      return tailVerb(args);
    default:
      throw new Error(`cli.mts: unknown verb ${verb}`);
  }
}

main(process.argv[2] ?? "", process.argv.slice(3)).catch((e) => {
  console.error(`fab: ${e instanceof Error ? e.message : String(e)}`);
  process.exitCode = 1;
});
