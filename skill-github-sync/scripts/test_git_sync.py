#!/usr/bin/env python3
import json
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT = Path(__file__).with_name("git_sync.py")


def git(repo, *args):
    subprocess.run(["git", *args], cwd=repo, check=True, capture_output=True, text=True)


def main():
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        remote = root / "remote.git"
        repo = root / "repo"
        subprocess.run(["git", "init", "--bare", remote], check=True, capture_output=True, text=True)
        subprocess.run(["git", "clone", remote, repo], check=True, capture_output=True, text=True)
        git(repo, "config", "user.email", "test@example.test")
        git(repo, "config", "user.name", "Test User")
        (repo / "README.md").write_text("# Test\n", encoding="utf-8")
        git(repo, "add", "README.md")
        git(repo, "commit", "-m", "init")
        git(repo, "push", "-u", "origin", "master")
        (repo / "draft.tmp").write_text("junk", encoding="utf-8")
        audit = subprocess.run([sys.executable, SCRIPT, "audit", repo], check=True, capture_output=True, text=True)
        data = json.loads(audit.stdout)
        assert data["dirty"] is True
        assert any(item["type"] == "junk" for item in data["review_items"])
        (repo / "draft.tmp").unlink()
        (repo / "README.md").write_text("# Test\nchange\n", encoding="utf-8")
        pushed = subprocess.run(
            [sys.executable, SCRIPT, "commit-push", repo, "--message", "update readme", "--files", "README.md"],
            check=True,
            capture_output=True,
            text=True,
        )
        assert json.loads(pushed.stdout)["pushed"] is True
        (repo / "AGENTS.md").write_text("unrelated\n", encoding="utf-8")
        git(repo, "add", "AGENTS.md")
        (repo / "README.md").write_text("# Test\nchange\nmore\n", encoding="utf-8")
        blocked = subprocess.run(
            [sys.executable, SCRIPT, "commit-push", repo, "--message", "must not sweep", "--files", "README.md"],
            capture_output=True,
            text=True,
        )
        assert blocked.returncode != 0
        err = json.loads(blocked.stderr.strip())
        assert err["reason"] == "staged_outside_files"
        assert "AGENTS.md" in err["paths"]
    print("ok")


if __name__ == "__main__":
    main()
