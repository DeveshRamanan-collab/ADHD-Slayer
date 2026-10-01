# P02-system-design questions
- OPEN: Does the MVP include any server (push backstop, Live Activity push-to-start) given system-design.md places it unlabelled while K.5 says local-only? → default: no server at MVP; push backstop and push-to-start deferred with sync to v1.
- OPEN: Is "dose reminder anchored to actual wake" (system-design.md:183) kept? → default: dropped; it breaches RL-6; reminders stay at user-set times.
- OPEN: Is PCC or E2E sync an acceptable exit for health data (system-design.md:36)? → default: no, RL-9 governs; Phase 5 records the conflict.
<!-- END OF FILE -->
