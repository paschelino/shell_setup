# Specs

Work on this repository that takes more than one session is planned here, so a
session can start cold from files instead of from a conversation.

- `projects/<id>/spec.md`: what to build, with checkable acceptance criteria and
  a Tasks table of session-sized steps.
- `projects/<id>/run-brief.md`: how to work on it, what must never happen, and
  one kickoff prompt per task that a cleared session can be given verbatim.
- `projects/<id>/progress.md`: the hand-off log between sessions, newest entry
  on top. Each entry covers done, open, surprises and the next step.
- `decisions/ADR-<NNNN>-<title>.md`: decisions that would otherwise get
  re-argued. Accepted ADRs are never rewritten, only superseded.

Every session ends with the hand-off checklist in the project's `run-brief.md`.
This repository is public: specs name no private project, path or account. Such
details live in files under `~/.config/zp/`, which the specs point to by path.
