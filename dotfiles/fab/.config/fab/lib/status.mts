// Reporting: the run's events.jsonl, and the multiplexer through `mx`. mx is
// a host-side command; if it is missing the run goes on without it.
import { appendFileSync } from "node:fs";
import { execFileSync } from "node:child_process";

export type State = "working" | "waiting" | "done" | "error" | "idle" | "none";

export class Reporter {
  private readonly eventsPath: string;
  private readonly label: string;

  // Node runs this with type stripping only, which has no parameter properties.
  constructor(eventsPath: string, label: string) {
    this.eventsPath = eventsPath;
    this.label = label;
  }

  event(type: string, data: Record<string, unknown> = {}) {
    const line = JSON.stringify({
      at: new Date().toISOString(),
      type,
      ...data,
    });
    appendFileSync(this.eventsPath, line + "\n");
  }

  mx(args: string[]) {
    try {
      execFileSync("mx", args, { stdio: "ignore", timeout: 15_000 });
    } catch {
      // mx missing or its host unreachable: the run must not fail on reporting.
    }
  }

  state(state: State, message?: string) {
    const text = message ? `${this.label}: ${message}` : this.label;
    this.mx(["state", state, "-m", text]);
  }

  notify(title: string, body: string) {
    this.mx(["notify", title, body]);
  }
}
