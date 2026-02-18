- всегда создавай файл architecture.md в котором будет описана структура всего проекта и инфо что делает каждый файл с ссылками на эти файлы
- обновляй файл architecture.md только если добавляешь, удаляешь, создаешь (файл, функции) чтобы он был всегда актуальным кроме информации о статусе проекта и тестировании
- при использовании любых зависимостей используй MCP context7-mcp он покажет актуальную информацию
- никогда не добавляй в architecture.md информацию о том что было исправлено или выполнено в нем должна быть информация только об архитектуре проека и больше ничего
- для контекста используй файл architecture.md
- никогда не исаользуй команды git add и git commit

- если что-то правиш в коде проверяй изменения на синтаксис и ошибки компиляции


# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds


EXAMPLES:
bd ready	List tasks with no open blockers.
bd create "Title" -p 0	Create a P0 task.
bd dep add <child> <parent> Link tasks (blocks, related, parent-child).
bd show <id> View task details and audit trail.
