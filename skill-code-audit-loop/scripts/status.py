#!/usr/bin/env python3
"""Loop status for the code-audit-loop skill.

Two uses:
  python status.py [DIR]                 -> print where the loop is, in plain English
  python status.py DIR set k=v [k=v ...] -> update the state, then print it
  python status.py --selftest            -> run the built-in check

State is one small file: DIR/state.json. DIR defaults to "code-audit-loop".
No dependencies — standard library only.
"""
import json
import sys
import tempfile
from datetime import date
from pathlib import Path

INT_FIELDS = {"round", "max_rounds"}
DEFAULTS = {"phase": "?", "round": 1, "turn": "code", "verdict": "pending", "max_rounds": 3}


def state_path(dir_: str) -> Path:
    return Path(dir_) / "state.json"


def load(dir_: str):
    p = state_path(dir_)
    if not p.exists():
        return None
    return json.loads(p.read_text(encoding="utf-8"))


def save(dir_: str, state: dict) -> None:
    p = state_path(dir_)
    p.parent.mkdir(parents=True, exist_ok=True)
    state["updated"] = date.today().isoformat()
    p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")


def apply_set(dir_: str, pairs) -> dict:
    state = load(dir_) or dict(DEFAULTS)
    for pair in pairs:
        if "=" not in pair:
            raise SystemExit(f"bad set argument (need key=value): {pair!r}")
        k, v = pair.split("=", 1)
        state[k] = int(v) if k in INT_FIELDS else v
    save(dir_, state)
    return state


def next_action(state: dict) -> str:
    turn = state.get("turn", "code")
    verdict = state.get("verdict", "pending")
    rnd = int(state.get("round", 1))
    cap = int(state.get("max_rounds", 3))
    phase = state.get("phase", "?")

    if verdict == "greenlight" or turn == "done":
        return "GREEN. Next: the human gives the final OK. Loop complete for this phase."
    if turn == "blocked":
        return "BLOCKED at the round cap. Next: the human decides how to proceed (the open fixes are in the plan)."
    if turn == "code":
        return f"Coder to implement Phase {phase}, update its docs, self-check, then hand to AUDIT."
    if turn == "audit":
        return f"Run a FRESH Auditor (code-audit, phase-gate mode) on Phase {phase}, then read the verdict from the plan."
    if turn == "fix":
        if rnd >= cap:
            return f"Round cap ({cap}) reached. Next: STOP and show the open fixes to the human - do not re-audit automatically."
        return f"Coder to implement only the latest Fix Plan (round {rnd}), run each fix's test, then re-audit as round {rnd + 1}."
    return "Unknown turn. Next: re-check the state or restart the loop."


def report(dir_: str) -> str:
    state = load(dir_)
    if state is None:
        return (
            f"Loop not started (no {state_path(dir_)}).\n"
            "Next: Turn CODE - implement the phase, then hand to AUDIT."
        )
    lines = [
        f"Phase   : {state.get('phase', '?')}",
        f"Round   : {state.get('round', 1)} of {state.get('max_rounds', 3)} max",
        f"Turn    : {state.get('turn', 'code')}",
        f"Verdict : {state.get('verdict', 'pending')}",
        f"Updated : {state.get('updated', '?')}",
        "",
        "-> " + next_action(state),
    ]
    return "\n".join(lines)


def selftest() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        d = str(Path(tmp) / "code-audit-loop")
        assert load(d) is None, "fresh dir should have no state"
        assert "not started" in report(d).lower()

        apply_set(d, ["phase=3", "round=1", "turn=audit", "verdict=pending"])
        s = load(d)
        assert s["phase"] == "3" and s["round"] == 1 and isinstance(s["round"], int)
        assert "fresh auditor" in next_action(s).lower()

        apply_set(d, ["turn=fix", "verdict=fixes", "round=3", "max_rounds=3"])
        assert "cap" in next_action(load(d)).lower(), "cap must trigger at round==max"

        apply_set(d, ["turn=done", "verdict=greenlight"])
        assert "green" in next_action(load(d)).lower()
    print("selftest OK")


def main(argv) -> None:
    args = argv[1:]
    if args and args[0] == "--selftest":
        selftest()
        return
    dir_ = args[0] if args else "code-audit-loop"
    if len(args) >= 2 and args[1] == "set":
        apply_set(dir_, args[2:])
        print(report(dir_))
        return
    print(report(dir_))


if __name__ == "__main__":
    main(sys.argv)
