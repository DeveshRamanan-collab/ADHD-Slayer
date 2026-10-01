author: orchestrator
# Session tool list facts (session 2, 2026-10-01) — evidence for PREFLIGHT rows on AskUserQuestion and browser tools
Source: the tool definitions and the deferred-tool list presented to the orchestrator at the start of session 2 (no call needed to read them).
```output
Top-level tools: Agent, Artifact, Bash, Edit, ListAgents, Read, ReportFindings, ScheduleWakeup, SendFeedback, Skill, ToolSearch, Workflow, Write
Deferred tools (names only, non-MCP): ArtifactComments, ArtifactData, CronCreate, CronDelete, CronList, DesignSync, EndConversation, EnterPlanMode, EnterWorktree, ExitPlanMode, ExitWorktree, LSP, Monitor, NotebookEdit, PushNotification, RemoteTrigger, SendMessage, TaskStop, WebFetch, WebSearch
AskUserQuestion: not present in either list
Browser tools (Claude in Chrome / built-in browser, names containing "chrome", "browser_" or "computer"): none present; only the skills anthropic-skills:chrome-browser, built-in-browser and computer-use are listed, which need a connected browser extension or app that is not connected
```
<!-- END OF FILE -->
