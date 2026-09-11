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
