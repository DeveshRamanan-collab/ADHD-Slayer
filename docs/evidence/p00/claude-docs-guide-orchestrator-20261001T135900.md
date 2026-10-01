author: orchestrator
# Claude Docs connector harmless call — guide(items=["topic.index"]) at 2026-10-01T13:59:00+1000
Result: the guide text returned (begins with the line below). It documents tools batch, guide, update, create, read, query, delete; a doc link `https://claude.ai/[code/]artifact/<id>` is read with `read( ref = {"object":"project","id":"<doc id>"} )`.
```output
# topic.index
Docs are living documents: a doc holds tabs, each tab holds prose, tables, charts and chips; tools `batch`,
`guide` and `update` (always listed) + `create` `read` `query` `delete` (loaded through your tool search when a task
needs them).
```
