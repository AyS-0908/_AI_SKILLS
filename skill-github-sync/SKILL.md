---
name: github-sync
description: >
  Deterministic local Git/GitHub sync helper for AI agents. Trigger for: user asks
  to initialize a local Git repo, create or rename a GitHub repo, push files to
  GitHub, sync a local repo with GitHub, pull latest changes, publish local skill
  changes, inspect stale/untracked files before a push, stage cleanup changes, or
  reduce token-heavy Git command loops. Do NOT trigger for: reviewing GitHub PR
  comments, fixing CI failures, managing GitHub issues/releases, or creating PRs
  when no local repository sync is needed.
status: active
triggers:
  - push to GitHub
  - sync with GitHub
  - git push
  - git pull
  - publish skill
  - stale files
---

# GitHub Sync

## Gotchas

- Never stage the whole worktree until the script audit proves scope is clean or the user explicitly confirms it.
- `git pull` must be fast-forward only. Stop on conflicts; do not auto-merge.
- Treat untracked files, deletions, conflict markers, and generated junk as review items before commit.
- Use existing GitHub/PR tools for pull requests. This skill only handles local Git sync.
- `create-repo` and `rename-repo` call `gh api`; verify auth first if they fail.

## Workflow

1. Find the repository root:
   ```powershell
   git -C "<repo>" rev-parse --show-toplevel
   ```
   If missing, initialize it:
   ```powershell
   python "<skill>/scripts/git_sync.py" init "<repo>"
   ```
2. Run the deterministic audit:
   ```powershell
   python "<skill>/scripts/git_sync.py" audit "<repo>" --fetch
   ```
3. Read only the JSON summary unless `review_items` requires targeted file inspection.
4. IF `behind > 0` and the worktree is clean, run:
   ```powershell
   python "<skill>/scripts/git_sync.py" pull "<repo>"
   ```
5. IF committing:
   - Prefer `--files <path>...`.
   - Use `--all` only after audit/user confirmation.
   - If staging ignored/deleted cleanup paths only, use:
     ```powershell
     python "<skill>/scripts/git_sync.py" stage-cleanup "<repo>" --files "<file1>" "<file2>"
     ```
   - Keep the commit message short.
   ```powershell
   python "<skill>/scripts/git_sync.py" commit-push "<repo>" --message "<msg>" --files "<file1>" "<file2>"
   ```
6. IF creating or renaming a GitHub repo:
   ```powershell
   python "<skill>/scripts/git_sync.py" create-repo "<repo>" --name "<repo-name>" --owner "<owner>" --private
   python "<skill>/scripts/git_sync.py" rename-repo "<repo>" --owner "<owner>" --name "<old-name>" --new-name "<new-name>"
   ```
7. Report branch, commit, pushed state, GitHub URL, and remaining `review_items`.

## Stop Rules

- Stop if the audit shows unrelated changes, conflict markers, or generated junk unless the user confirms scope.
- Stop if pull is not fast-forward.
- Stop if push is rejected; run `audit --fetch` and explain `ahead/behind`.
