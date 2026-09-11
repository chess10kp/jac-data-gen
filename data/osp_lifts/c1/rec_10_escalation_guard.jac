"""Incident escalation paths lifted to OSP.

On-call teams are ``Team`` nodes; ``EscalatesTo`` edges point from a
team to the next escalation tier. Chains climb linearly. Escalation
loops are a known misconfiguration: the climb stops when it revisits
a team and returns the partial chain -- documented tolerance kept as
the walker's explicit cycle policy.
"""

node Team {
    has name: str;
    has tier: int;               # 1 = front line, higher = further up
    has members: list[str];      # on-call handles
}

edge EscalatesTo: Team --> Team {}

"""Build the fixture ladder deterministically; returns the front-line team."""
def build_ladder() -> Team {
    root ++> (exec_team := Team(name="exec", tier=3, members=["avery"]));
    root ++> (sre_lead := Team(name="sre-lead", tier=2, members=["blake"]));
    root ++> (frontend := Team(name="frontend", tier=1, members=["casey"]));
    root ++> (mobile := Team(name="mobile", tier=1, members=["dana"]));
    frontend +>:EscalatesTo:+> sre_lead;
    mobile +>:EscalatesTo:+> sre_lead;
    sre_lead +>:EscalatesTo:+> exec_team;
    return frontend;
}

"""Wire `name` to escalate to `parent` (None at the top); return it."""
def add_team(parent: Team | None, name: str, tier: int, members: list[str] | None = None) -> Team {
    mems = list(members) if members else [];
    root ++> (t := Team(name=name, tier=tier, members=mems));
    if parent is not None {
        t +>:EscalatesTo:+> parent;
    }
    return t;
}

walker LadderClimb {
    """Climbs EscalatesTo edges, stopping quietly on a misconfigured loop."""
    has hops: list[str] = [];
    has claimed: dict[str, bool] = {};

    can climb with Team entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.hops.append(here.name);
        visit [->:EscalatesTo:->] else { report self.hops; disengage; }
    }
}

"""Team names escalated-to from `team`, nearest first (excl. team)."""
def escalation_path(team: Team) -> list[str] {
    w = team spawn LadderClimb();
    return w.hops[1:];
}

"""True when incidents at `a` eventually reach `b`."""
def can_escalate(a: Team, b: Team) -> bool {
    return b.name in escalation_path(a);
}

"""Number of hops from `team` up its (possibly partial) ladder."""
def escalation_length(team: Team) -> int {
    return len(escalation_path(team));
}
test "escalation_path climbs nearest-first" {
    frontend = build_ladder();
    sre_lead = [t for t in [frontend -->][?:Team]][0];
    exec_team = [t for t in [sre_lead -->][?:Team]][0];
    mobile = [t for t in [sre_lead <--][?:Team] if t.name == "mobile"][0];
    assert escalation_path(frontend) == ["sre-lead", "exec"];
    assert escalation_path(exec_team) == [];
    assert can_escalate(frontend, exec_team);
    assert not can_escalate(mobile, mobile);
    assert escalation_length(mobile) == 2;
}

test "misconfigured loop stops with partial chain" {
    frontend = build_ladder();
    sre_lead = [t for t in [frontend -->][?:Team]][0];
    exec_team = [t for t in [sre_lead -->][?:Team]][0];
    exec_team +>:EscalatesTo:+> sre_lead;
    assert escalation_path(frontend) == ["sre-lead", "exec"];
}
test "add_team wires a new escalation tier" {
    frontend = build_ladder();
    sre_lead = [t for t in [frontend -->][?:Team]][0];
    exec_team = [t for t in [sre_lead -->][?:Team]][0];
    db = add_team(sre_lead, "db", 2, members=["erin"]);
    assert escalation_path(db) == ["sre-lead", "exec"];
    assert can_escalate(db, exec_team);
    assert escalation_length(db) == 2;
    top = add_team(None, "cto", 4);
    assert escalation_path(top) == [];
}
