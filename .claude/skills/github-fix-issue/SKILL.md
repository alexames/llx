---
name: github-fix-issue
description: Take a GitHub issue from open to resolved end to end - read it, implement the fix on a branch, open a PR, merge it, and close the issue with the PR number and a resolution note. Use ONLY when the user explicitly asks to implement/fix/resolve a specific issue end to end. FULL AUTO - this skill merges without waiting for review. Prefers the GitHub MCP server (github), falls back to gh.
---

# github-fix-issue

Resolve a GitHub issue end to end: implement, push, PR, **merge**, and close. Use the GitHub
MCP server (`github`) for issue/PR operations, falling back to the `gh` CLI.

> AUTHORIZED AUTO-MERGE (scoped): Alex explicitly opted THIS ONE skill into merging without
> review (full auto: merge + close). This is a deliberate exception to the standing rule
> "never merge until Alex says so" - that rule still governs ALL other work. Do not
> generalize this behavior to any other task or skill.

## Input
- `$ARGUMENTS`: the issue number (e.g. `25`), optionally `owner/repo#N`. If missing, ask.

## Procedure
1. **Read the issue.** `mcp__github__get_issue` (or `gh issue view <N> --json
   title,body,labels,number`). Restate the problem in one or two sentences and confirm the
   scope from the body before touching code.
2. **Branch.** Never work on `main`. Branch from an up-to-date `main` with a prefix matching
   the change type (from the issue's labels/content): feature -> `feature/`, bug -> `bug/`,
   refactor -> `refactor/`, docs -> `docs/`, tests -> `test/`
   (e.g. `feature/issue-25-callable-matcher`).
3. **Implement.** Make focused changes that satisfy the issue. Read surrounding code and
   match its style (module environments via `llx.environment`, matcher/class conventions).
   Add or extend tests - new features need tests; bug fixes need a reproducing test. Tests
   live in `tests/`, mirroring `src/`, and use the `llx.unit` describe/it/expect framework.
4. **Validate.**
   - Keep source ASCII and compatible with Lua 5.3+.
   - Install and run the full suite per CLAUDE.md: `luarocks make --local && lua test.lua`
     (the rockspec maps `llx.*` to `src/*`, so install before testing).
   - Report results honestly - do not merge on a red or unrun suite.
5. **Pre-commit review.** Spawn a problem-statement-only review subagent - give it ONLY the
   issue text and the diff, not your reasoning - and incorporate valid feedback before
   committing.
6. **Commit.** Small, focused commits. Summary line starts with a capital letter;
   NO conventional-commit prefixes (`feat:`/`fix:`). End the commit message with the
   Co-Authored-By trailer required by the harness.
7. **Push & PR.** Push the branch; open a PR (`gh pr create` or
   `mcp__github__create_pull_request`). Body uses **Summary / Changes / Testing** sections
   and contains `Closes #<N>` so the merge auto-closes the issue.
8. **Merge - guarded.** Merge ONLY if step 4 validation and the step 5 review both passed.
   If anything failed or is uncertain, STOP and report instead of merging. When clear, merge
   with a MERGE COMMIT, never squash: `gh pr merge <N> --merge` (or the MCP merge tool with
   the `merge` strategy).
9. **Resolve the issue.** Confirm it closed (the `Closes #N` link closes it on merge). Add a
   comment recording the PR number and a one-paragraph summary of HOW it was resolved
   (`gh issue comment <N>` / `mcp__github__add_issue_comment`). If it did not auto-close,
   close it explicitly.
10. **Delete the branch.** Once the merge is confirmed, delete the remote branch
    (`git push origin --delete <branch>`, or merge with `gh pr merge <N> --merge
    --delete-branch` in step 8) and the local branch (`git branch -d <branch>`; if the
    work was done in a worktree, removing the worktree and its branch covers this).
    Only delete AFTER confirming the PR merged - never delete an unmerged branch.
11. **Report** the branch, PR URL, merge status, branch cleanup, and the resolution comment.

## Conventions (llx)
- Never push to `main`; always branch + PR.
- Merge commits only (`--merge`), never `--squash`.
- Co-Authored-By trailer on commits; PR body in Summary / Changes / Testing form.
- ASCII-only source; Lua 5.3+ compatibility; tests accompany every change.
- If the branch ends up containing commits OUTSIDE the issue's scope, STOP and ask before
  pushing - do not merge a mixed-scope branch.
