#!/usr/bin/env python3
import argparse
import fnmatch
import json
import os
import subprocess
import sys
from pathlib import Path

JUNK = ("*.tmp", "*.bak", "*.log", "*.pyc", ".DS_Store", "Thumbs.db", "desktop.ini")
JUNK_DIRS = {"__pycache__", "node_modules", ".venv", "venv", "dist", "build"}
TEXT_EXTS = {
    ".md",
    ".txt",
    ".py",
    ".ps1",
    ".js",
    ".ts",
    ".json",
    ".yaml",
    ".yml",
    ".toml",
    ".html",
    ".css",
}


def run(repo, *args, check=True):
    p = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True)
    if check and p.returncode:
        raise SystemExit(json.dumps({"ok": False, "stage": "git " + " ".join(args), "stderr": p.stderr.strip()}))
    return p.stdout.strip()


def repo_root(repo):
    root = run(repo, "rev-parse", "--show-toplevel")
    return str(Path(root).resolve())


def current_branch(repo):
    return run(repo, "branch", "--show-current") or "HEAD"


def upstream(repo):
    p = subprocess.run(["git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"], cwd=repo, text=True, capture_output=True)
    return p.stdout.strip() if p.returncode == 0 else ""


def ahead_behind(repo, up):
    if not up:
        return 0, 0
    out = run(repo, "rev-list", "--left-right", "--count", f"{up}...HEAD")
    behind, ahead = [int(x) for x in out.split()]
    return ahead, behind


def porcelain(repo):
    out = run(repo, "status", "--porcelain=v1", "-uall")
    rows = []
    for line in out.splitlines():
        if not line:
            continue
        rows.append({"xy": line[:2], "path": line[3:]})
    return rows


def changed_paths(rows):
    paths = []
    for row in rows:
        path = row["path"]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        paths.append(path.strip('"'))
    return paths


def is_junk(path):
    parts = Path(path).parts
    if any(part in JUNK_DIRS for part in parts):
        return True
    return any(fnmatch.fnmatch(Path(path).name, pat) for pat in JUNK)


def has_conflict_marker(full):
    if full.suffix.lower() not in TEXT_EXTS or not full.exists() or full.stat().st_size > 1_000_000:
        return False
    try:
        text = full.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return False
    return "<<<<<<< " in text or "\n=======" in text or ">>>>>>> " in text


def audit(args):
    root = repo_root(args.repo)
    if args.fetch:
        run(root, "fetch", "--prune")
    branch = current_branch(root)
    up = upstream(root)
    ahead, behind = ahead_behind(root, up)
    rows = porcelain(root)
    paths = changed_paths(rows)
    review = []
    for row in rows:
        if row["xy"].startswith("??"):
            review.append({"type": "untracked", "path": row["path"]})
        if "D" in row["xy"]:
            review.append({"type": "deletion", "path": row["path"]})
    for path in paths:
        if is_junk(path):
            review.append({"type": "junk", "path": path})
        full = Path(root, path)
        if has_conflict_marker(full):
            review.append({"type": "conflict_marker", "path": path})
    print(json.dumps({
        "ok": True,
        "repo": root,
        "branch": branch,
        "upstream": up,
        "ahead": ahead,
        "behind": behind,
        "dirty": bool(rows),
        "changed_count": len(rows),
        "changes": rows[:80],
        "review_items": review[:80],
    }, separators=(",", ":")))


def pull(args):
    root = repo_root(args.repo)
    if porcelain(root):
        raise SystemExit(json.dumps({"ok": False, "stage": "prepull", "reason": "worktree_dirty"}))
    run(root, "fetch", "--prune")
    run(root, "pull", "--ff-only")
    print(json.dumps({"ok": True, "repo": root, "branch": current_branch(root), "pulled": True}, separators=(",", ":")))


def push_current(root, up):
    branch = current_branch(root)
    remote = up.split("/", 1)[0] if "/" in up else "origin"
    run(root, "push", "-u", remote, branch)
    return branch


def commit_push(args):
    root = repo_root(args.repo)
    if args.all and args.files:
        raise SystemExit(json.dumps({"ok": False, "stage": "stage", "reason": "use_files_or_all_not_both"}))
    run(root, "fetch", "--prune")
    up = upstream(root)
    ahead, behind = ahead_behind(root, up)
    if behind:
        raise SystemExit(json.dumps({"ok": False, "stage": "prepush", "reason": "behind_remote", "behind": behind}))
    if args.all:
        run(root, "add", "-A")
    else:
        if not args.files:
            raise SystemExit(json.dumps({"ok": False, "stage": "stage", "reason": "missing_files_or_all"}))
        run(root, "add", "--", *args.files)
    staged = run(root, "diff", "--cached", "--name-only")
    if not staged:
        if ahead:
            branch = push_current(root, up)
            print(json.dumps({"ok": True, "repo": root, "branch": branch, "pushed_existing": True}, separators=(",", ":")))
            return
        raise SystemExit(json.dumps({"ok": True, "repo": root, "message": "nothing_staged"}))
    run(root, "commit", "-m", args.message)
    commit = run(root, "rev-parse", "--short", "HEAD")
    branch = push_current(root, up)
    print(json.dumps({"ok": True, "repo": root, "branch": branch, "commit": commit, "pushed": True}, separators=(",", ":")))


def main():
    parser = argparse.ArgumentParser(description="Deterministic GitHub sync helper")
    sub = parser.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("audit")
    a.add_argument("repo")
    a.add_argument("--fetch", action="store_true")
    a.set_defaults(fn=audit)
    p = sub.add_parser("pull")
    p.add_argument("repo")
    p.set_defaults(fn=pull)
    c = sub.add_parser("commit-push")
    c.add_argument("repo")
    c.add_argument("--message", required=True)
    c.add_argument("--files", nargs="*")
    c.add_argument("--all", action="store_true")
    c.set_defaults(fn=commit_push)
    args = parser.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
