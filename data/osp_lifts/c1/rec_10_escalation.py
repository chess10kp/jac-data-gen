"""Incident escalation paths.

On-call teams link to their escalation tier through ``parent``
pointers. Escalation chains ascend tier by tier. Escalation loops are
a known misconfiguration: the climb stops when it revisits a team and
returns the partial chain -- documented tolerance, not silent hang.
"""


class Team:
    def __init__(self, name, tier):
        self.name = name
        self.tier = tier          # 1 = front line, higher = further up
        self.parent = None        # Team | None (top of escalation ladder)
        self.members = []         # list[str] on-call handles


class EscalationLoopError(Exception):
    pass


def add_team(parent, name, tier, members=None):
    """Wire ``name`` to escalate to ``parent`` (None at the top)."""
    t = Team(name, tier)
    t.members = list(members) if members else []
    if parent is not None:
        t.parent = parent
    return t


def _climb(team, seen):
    if team.name in seen:
        return []                 # misconfigured loop: stop quietly
    seen.add(team.name)
    if team.parent is None:
        return []
    return [team.parent.name] + _climb(team.parent, seen)


def escalation_path(team):
    """Team names escalated-to from ``team``, nearest first (excl. team)."""
    return _climb(team, set())


def can_escalate(a, b):
    """True when incidents at ``a`` eventually reach ``b``."""
    return b.name in escalation_path(a)


def escalation_length(team):
    """Number of hops from ``team`` up its (possibly partial) ladder."""
    return len(escalation_path(team))
