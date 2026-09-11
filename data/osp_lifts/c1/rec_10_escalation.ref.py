"""Reference harness for rec_10_escalation (deterministic fixture)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from rec_10_escalation import add_team, can_escalate, escalation_length, escalation_path

exec_team = add_team(None, "exec", 3, ["avery"])
sre_lead = add_team(exec_team, "sre-lead", 2, ["blake"])
frontend = add_team(sre_lead, "frontend", 1, ["casey"])
mobile = add_team(sre_lead, "mobile", 1, ["dana"])

p_front = escalation_path(frontend)
print("escalation_path(frontend):", p_front)
assert p_front == ["sre-lead", "exec"], p_front

p_exec = escalation_path(exec_team)
print("escalation_path(exec):", p_exec)
assert p_exec == [], p_exec

checks = {
    "front_to_exec": can_escalate(frontend, exec_team),
    "mobile_to_mobile": can_escalate(mobile, mobile),
    "exec_to_front": can_escalate(exec_team, frontend),
}
print("can_escalate:", checks)
assert checks == {"front_to_exec": True, "mobile_to_mobile": False,
                  "exec_to_front": False}, checks

lengths = {"frontend": escalation_length(frontend), "mobile": escalation_length(mobile)}
print("escalation lengths:", lengths)
assert lengths == {"frontend": 2, "mobile": 2}, lengths

# Misconfigured loop: mobile's parent points back at frontend.
mobile.parent = frontend
looped = escalation_path(frontend)
print("escalation_path with loop (partial, tolerated):", looped)
assert looped == ["sre-lead", "exec"], looped

print("rec_10_escalation: all assertions passed")
