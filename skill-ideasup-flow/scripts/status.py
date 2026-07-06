#!/usr/bin/env python3
"""IdeaUp Flow pipeline status: which stage artifacts exist, what runs next.

Usage: python status.py [artifact_dir]   (default: ./ideasup)
Exit codes: 0 = ok, 2 = artifact dir missing.
"""
import sys
from pathlib import Path

STAGES = [
    ("1", "Pain",          "1-pain.md",           "available"),
    ("2", "Opportunity",   "2-opportunity.md",    "available"),
    ("3", "Idea",          "3-idea.md",           "available"),
    ("4", "Business Plan", "4-business-plan.md",  "MISSING SOURCE"),
    ("5", "User Story",    "5-user-story.md",     "available"),
    ("6", "Mockup",        "6-mockup.html",       "available"),
    ("7", "Specification", "7-specification.md",  "available"),
    ("8", "AI-Coder rules","8-ai-coder-rules.md", "MISSING SOURCE"),
]


def main() -> int:
    d = Path(sys.argv[1] if len(sys.argv) > 1 else "ideasup")
    if not d.is_dir():
        print(f"NO ARTIFACT DIR: {d} (start with: Run pain, or create the dir)")
        return 2
    next_stage = None
    print(f"Artifact dir: {d.resolve()}")
    print(f"{'#':<2} {'Stage':<14} {'Artifact':<20} Status")
    for num, name, fname, source in STAGES:
        f = d / fname
        if f.is_file() and f.stat().st_size > 0:
            status = "DONE"
        elif source == "MISSING SOURCE":
            status = "SKIP (missing source)"
        else:
            status = "pending"
            if next_stage is None:
                next_stage = f"{num} - {name}"
        print(f"{num:<2} {name:<14} {fname:<20} {status}")
    print(f"\nNEXT: {'Run stage ' + next_stage if next_stage else 'pipeline complete'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
