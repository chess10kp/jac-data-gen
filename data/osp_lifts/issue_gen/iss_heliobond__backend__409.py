"""Feature-flag evaluation over an admin-controllable depends_on graph.

Before-code synthesized from Heliobond/backend#409: ``evaluateFlag`` resolves
each flag's ``depends_on`` recursively and crashes the process when admins
load a circular flag set (a depends on b, b depends on a). The suggested fix
-- a visited set threaded through the evaluation that yields a
``dependency_cycle`` result when a flag is revisited within one evaluation
-- is the behavior coded here. A flag is on when its own gate passes
(``enabled`` and the caller's rollout bucket below ``rollout_percentage``)
and every flag in its dependency closure passes its own gate. Failure
reasons resolve deterministically: any revisit in the closure is a cycle
first; otherwise the lexicographically smallest unresolvable dependency,
then the smallest gate-failing flag name, win. depends_on lists, a visited
set, and a hand-rolled stack walk below.
"""


class FlagSet:
    def __init__(self):
        self.flags = {}   # name -> {"enabled","rollout_percentage","depends_on"}

    def load(self, spec):
        """Replace the whole set (POST /admin/flags/load semantics)."""
        self.flags = {}
        self.merge(spec)

    def merge(self, spec):
        """Add or update flags in place (POST /admin/flags/merge semantics)."""
        for name, raw in spec.items():
            f = {
                "enabled": bool(raw.get("enabled", False)),
                "rollout_percentage": raw.get("rollout_percentage", 100),
                "depends_on": list(raw.get("depends_on", [])),
            }
            self.flags[name] = f

    def _closure(self, name, out, meta):
        """Stack walk collecting the dependency closure; a revisit marks a cycle."""
        meta["revisited"] = meta.get("revisited", False)
        stack = [name]
        while stack:
            cur = stack.pop()
            if cur in out:
                meta["revisited"] = True
                continue
            if cur not in self.flags:
                continue
            out.add(cur)
            stack.extend(self.flags[cur]["depends_on"])

    def evaluate(self, name, ctx=None):
        bucket = (ctx or {}).get("bucket", 0)
        if name not in self.flags:
            return {"name": name, "value": False, "reason": "unknown_flag"}
        closure = set()
        meta = {}
        self._closure(name, closure, meta)
        if meta["revisited"]:
            return {"name": name, "value": False, "reason": "dependency_cycle"}
        # smallest unresolvable dependency name wins
        unknown = []
        for f in closure:
            for dep in self.flags[f]["depends_on"]:
                if dep not in self.flags and dep not in unknown:
                    unknown.append(dep)
        if unknown:
            return {"name": name, "value": False,
                    "reason": "unknown_dependency:" + min(unknown)}
        # smallest gate-failing flag name wins
        failed = [f for f in closure
                  if not (self.flags[f]["enabled"]
                          and bucket < self.flags[f]["rollout_percentage"])]
        if failed:
            return {"name": name, "value": False, "reason": "gate:" + min(failed)}
        return {"name": name, "value": True, "reason": "ok"}
