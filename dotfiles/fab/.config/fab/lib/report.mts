// The task report: what an agent emits at the end of each task, inside a
// <report> tag, and sandcastle validates against this schema.
import { z } from "zod";

export const taskReport = z.object({
  task: z.string(),
  status: z.enum(["done", "parked", "failed"]),
  summary: z.string(),
  decisions: z.array(z.string()).default([]),
  parked: z
    .array(z.object({ question: z.string(), assumption: z.string() }))
    .default([]),
  dependencies: z.array(z.string()).default([]),
  deleted: z.array(z.string()).default([]),
  demo: z.string().default(""),
});

export type TaskReport = z.infer<typeof taskReport>;

export const REPORT_TAG = "report";
