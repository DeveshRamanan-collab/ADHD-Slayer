# P02-spec-backend questions
- OPEN: The encrypted server backup in docs/build-spec/02-backend.md sends health data off the device, which RL-9 does not list as an exception. Should the reconciliation treat server backup as out of MVP scope? → Default adopted: record it faithfully with `[RED-LINE RL-9]` and leave the decision to the orchestrator (K.5 local-only MVP default).
- OPEN: docs/api-design.md §5 (device-key relay, batches, APNs) and docs/build-spec/02-backend.md (provider sign-in, snapshots, no push) describe two incompatible backends. Which one is current? → Default adopted: 02-backend.md (newer build spec, mirrored on the Figma Build spec page per prompts/SOURCE_MAP.md); api-design.md rows kept and listed as conflicts.
<!-- END OF FILE -->
