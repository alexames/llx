---
name: github-file-issue
description: Research and create a well-scoped GitHub issue from a description. Use when the user asks to file/open/create/write up an issue, turn a task or bug into a tracker item, or capture a plan as an issue. Prefers the GitHub MCP server (github) and falls back to the gh CLI.
---

# github-file-issue

Author a precise, actionable GitHub issue and create it on the tracker. Use the GitHub MCP
server (the `github` server's `mcp__github__*` tools); fall back to the `gh` CLI if those
tools are unavailable or not yet connected.

## Input
- `$ARGUMENTS`: a free-form description of the issue (bug, feature, or task). If empty, ask
  the user what the issue should cover before proceeding.

## Procedure
1. **Target repo.** Default to the current repo's `origin`
   (`gh repo view --json nameWithOwner -q .nameWithOwner`). Confirm only if ambiguous.
2. **Research before writing.** Do NOT file a vague issue. Read the relevant code so the
   issue cites concrete `path:line` anchors and names the real functions/files involved.
   Spawn an Explore subagent for anything broad; keep the conclusions, not the file dumps.
3. **Draft the body** with these sections (omit any that don't apply):
   - **Summary** - one paragraph: what and why.
   - **Current state** - how it works today, with `path:line` citations and short quoted
     snippets.
   - **Proposed approach** - concrete steps; surface genuine design decisions and open
     questions instead of hand-waving past them.
   - **Out of scope / Related** - cross-link sibling issues with `#N`.
   - **Testing** - how it should be verified (`llx.unit` tests; run the suite with
     `luarocks make --local && lua test.lua` per CLAUDE.md; manual steps).
   - **Notes for the implementing agent** - conventions that apply (review-before-commit,
     ASCII-only source, Lua 5.3+ compatibility).
4. **Labels.** Choose from the repo's EXISTING labels only (`gh label list`); never invent
   labels. llx currently has only the GitHub default labels, so this usually means
   `enhancement` or `bug`.
5. **Create the issue.**
   - Preferred: the GitHub MCP `create_issue` tool, passing owner/repo/title/body/labels.
   - Fallback: write the body to a temp file and
     `gh issue create --title "..." --body-file <file> --label A --label B` (repeated
     `--label` flags, not comma-separated).
6. **Cross-link.** If you filed several related issues, edit them to reference each other
   by `#N` once all numbers are known.
7. **Report** the created issue number(s) and URL(s).

## Conventions
- Keep the body ASCII (llx source and docs are ASCII-only).
- Title: a clear summary starting with a capital letter; no conventional-commit prefixes.
- Prefer flagging real design decisions as open questions over guessing the answer.
