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


def gh(repo, *args, check=True):
    p = subprocess.run(["gh", *args], cwd=repo, text=True, capture_output=True)
    if check and p.returncode:
        raise SystemExit(json.dumps({"ok": False, "stage": "gh " + " ".join(args), "stderr": p.stderr.strip()}))
    return p.stdout.strip()


def stage_paths(root, files=None):
    if files:
        p = subprocess.run(["git", "add", "-A", "--", *files], cwd=root, text=True, capture_output=True)
        if p.returncode:
            for path in files:
                full = Path(root, path)
                tracked = subprocess.run(["git", "ls-files", "--error-unmatch", "--", path], cwd=root, text=True, capture_output=True)
                staged = subprocess.run(["git", "diff", "--cached", "--name-only", "--", path], cwd=root, text=True, capture_output=True)
                if not full.exists() and staged.stdout.strip():
                    continue
                if not full.exists() and tracked.returncode == 0:
                    run(root, "rm", "--cached", "--", path)
                else:
                    raise SystemExit(json.dumps({"ok": False, "stage": "git add -A -- " + " ".join(files), "stderr": p.stderr.strip()}))
        return
    run(root, "add", "-A")


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
        rows.append({"xy": line[:2], "path": line[3:] if line[2:3] == " " else line[2:]})
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
    return any(line.startswith(("<<<<<<< ", "=======", ">>>>>>> ")) for line in text.splitlines())


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


def init(args):
    repo = str(Path(args.repo).resolve())
    Path(repo).mkdir(parents=True, exist_ok=True)
    root_probe = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=repo, text=True, capture_output=True)
    if root_probe.returncode:
        run(repo, "init")
        root = repo_root(repo)
    else:
        root = str(Path(root_probe.stdout.strip()).resolve())
    if args.branch:
        run(root, "branch", "-M", args.branch)
    print(json.dumps({"ok": True, "repo": root, "branch": current_branch(root), "initialized": bool(root_probe.returncode)}, separators=(",", ":")))


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


def set_remote(root, remote, url):
    exists = subprocess.run(["git", "remote", "get-url", remote], cwd=root, text=True, capture_output=True)
    if exists.returncode:
        run(root, "remote", "add", remote, url)
    else:
        run(root, "remote", "set-url", remote, url)


def create_repo(args):
    root = repo_root(args.repo)
    login = gh(root, "api", "user", "--jq", ".login")
    owner = args.owner or login
    endpoint = "user/repos" if owner == login else f"orgs/{owner}/repos"
    visibility = "false" if args.public else "true"
    created = gh(root, "api", endpoint, "-f", f"name={args.name}", "-f", f"private={visibility}", "-f", f"description={args.description}", "--jq", "{full_name:.full_name,clone_url:.clone_url,html_url:.html_url}")
    data = json.loads(created)
    if args.remote:
        set_remote(root, args.remote, data["clone_url"])
    print(json.dumps({"ok": True, "repo": root, "github": data["full_name"], "url": data["html_url"], "remote": args.remote}, separators=(",", ":")))


def rename_repo(args):
    root = repo_root(args.repo)
    renamed = gh(root, "api", f"repos/{args.owner}/{args.name}", "-X", "PATCH", "-f", f"name={args.new_name}", "--jq", "{full_name:.full_name,clone_url:.clone_url,html_url:.html_url}")
    data = json.loads(renamed)
    if args.remote:
        set_remote(root, args.remote, data["clone_url"])
    print(json.dumps({"ok": True, "repo": root, "github": data["full_name"], "url": data["html_url"], "remote": args.remote}, separators=(",", ":")))


def stage_cleanup(args):
    root = repo_root(args.repo)
    if args.all and args.files:
        raise SystemExit(json.dumps({"ok": False, "stage": "stage-cleanup", "reason": "use_files_or_all_not_both"}))
    if not args.all and not args.files:
        raise SystemExit(json.dumps({"ok": False, "stage": "stage-cleanup", "reason": "missing_files_or_all"}))
    stage_paths(root, None if args.all else args.files)
    staged = run(root, "diff", "--cached", "--name-status")
    print(json.dumps({"ok": True, "repo": root, "staged": staged.splitlines()}, separators=(",", ":")))


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
        stage_paths(root)
    else:
        if not args.files:
            raise SystemExit(json.dumps({"ok": False, "stage": "stage", "reason": "missing_files_or_all"}))
        # git commit -- <paths> would commit worktree state (breaking --cached removals),
        # so instead refuse to sweep pre-staged paths outside --files into the commit
        pre = run(root, "diff", "--cached", "--name-only")
        if pre:
            allowed = set(run(root, "diff", "--cached", "--name-only", "--", *args.files).splitlines())
            outside = [p for p in pre.splitlines() if p not in allowed]
            if outside:
                raise SystemExit(json.dumps({"ok": False, "stage": "precommit", "reason": "staged_outside_files", "paths": outside[:40]}))
        stage_paths(root, args.files)
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
    i = sub.add_parser("init")
    i.add_argument("repo")
    i.add_argument("--branch", default="main")
    i.set_defaults(fn=init)
    a = sub.add_parser("audit")
    a.add_argument("repo")
    a.add_argument("--fetch", action="store_true")
    a.set_defaults(fn=audit)
    p = sub.add_parser("pull")
    p.add_argument("repo")
    p.set_defaults(fn=pull)
    cr = sub.add_parser("create-repo")
    cr.add_argument("repo")
    cr.add_argument("--name", required=True)
    cr.add_argument("--owner")
    cr.add_argument("--description", default="")
    vis = cr.add_mutually_exclusive_group()
    vis.add_argument("--private", action="store_true", default=True)
    vis.add_argument("--public", action="store_true")
    cr.add_argument("--remote", default="origin")
    cr.set_defaults(fn=create_repo)
    rr = sub.add_parser("rename-repo")
    rr.add_argument("repo")
    rr.add_argument("--owner", required=True)
    rr.add_argument("--name", required=True)
    rr.add_argument("--new-name", required=True)
    rr.add_argument("--remote", default="origin")
    rr.set_defaults(fn=rename_repo)
    s = sub.add_parser("stage-cleanup")
    s.add_argument("repo")
    s.add_argument("--files", nargs="*")
    s.add_argument("--all", action="store_true")
    s.set_defaults(fn=stage_cleanup)
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
