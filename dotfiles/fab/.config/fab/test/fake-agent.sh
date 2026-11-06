#!/bin/sh
# A stand-in for the agent, for testing fab without a token: reads the prompt
# on stdin, does the smallest thing a task could mean, commits it and emits the
# report. Driven by `fab run --agent fake` with FAB_FAKE_AGENT=<this file>.
#
#   FAB_FAKE_SLEEP=<seconds>   work slowly, for deadline tests
#   FAB_FAKE_FAIL=<task ids>   report these tasks as failed (space separated)
#   FAB_FAKE_PARK=<task ids>   report these as parked, with a question
#   FAB_FAKE_NO_REPORT=<ids>   emit no report at all, to test the error path
set -eu
prompt=$(cat)
task=$(printf '%s\n' "$prompt" | sed -n 's/^- Task: \(.*\)$/\1/p' | head -1)
spec=$(printf '%s\n' "$prompt" | sed -n 's/^- Spec: `\([^`]*\)`.*$/\1/p' | head -1)
[ -n "$task" ] || { echo "fake agent: no task in prompt" >&2; exit 1; }
echo "fake agent: task $task in $(pwd)"
[ -z "${FAB_FAKE_SLEEP:-}" ] || sleep "$FAB_FAKE_SLEEP"

has() { case " $1 " in *" $task "*) return 0 ;; esac; return 1; }

if has "${FAB_FAKE_NO_REPORT:-}"; then
  echo "fake agent: ending without a report"
  exit 0
fi
if has "${FAB_FAKE_FAIL:-}"; then
  printf '<report>{"task":"%s","status":"failed","summary":"made to fail","decisions":[],"parked":[],"dependencies":[],"deleted":[],"demo":""}</report>\n' "$task"
  exit 0
fi
if has "${FAB_FAKE_PARK:-}"; then
  printf '<report>{"task":"%s","status":"parked","summary":"needs the maintainer","decisions":[],"parked":[{"question":"Which colour?","assumption":"blue"}],"dependencies":[],"deleted":[],"demo":""}</report>\n' "$task"
  exit 0
fi

echo "hello from $task" > "$task.txt"
# Mark the row done, as a real agent would.
[ -z "$spec" ] || sed -i.bak "s/^| $task  *| /| $task | **Done** $(date +%Y-%m-%d). /" "$spec" && rm -f "$spec.bak"
git add -- "$task.txt" ${spec:+"$spec"}
git -c user.name=fake -c user.email=fake@example.invalid commit -q -m "feat($task): fake work" -- "$task.txt" ${spec:+"$spec"}
sha=$(git rev-parse --short HEAD)
printf '<report>{"task":"%s","status":"done","summary":"wrote %s.txt in %s","decisions":["used a plain text file"],"parked":[],"dependencies":[],"deleted":[],"demo":"cat %s.txt"}</report>\n' "$task" "$task" "$sha" "$task"
