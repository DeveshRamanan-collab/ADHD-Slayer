author: orchestrator
# WebFetch harmless calls (one-time-prompt trigger, OM-1.4), session 2, 2026-10-01 — G0 loop 3 evidence for PREFLIGHT
Three WebFetch calls to domains not fetched before; each returned without any permission dialog (bypassPermissions mode). Results verbatim (first line):
```output
https://www.legislation.nsw.gov.au/ → The server returned HTTP 403 Forbidden.
https://www.apple.com/au/ios/ios-26/ → The server returned HTTP 404 Not Found.
https://www.swift.org/ → # Swift Programming Language / The page title is **"Swift Programming Language"**
```
Consequence: legislation.nsw.gov.au refuses WebFetch as well as the scripted route; Phase 11 uses legislation.gov.au (FACT-010) for Commonwealth law and records NSW sources separately.
<!-- END OF FILE -->
