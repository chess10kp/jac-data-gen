"""Org-chart reporting lines lifted to OSP.

Employees are ``Employee`` nodes; ``ReportsTo`` edges point from an
employee to their manager. Chain queries climb manager edges with a
linear walker; subtree totals are folded bottom-up in exit abilities.
The per-walker ``claimed`` map is the explicit cycle policy (jac 0.36.1
walkers have no built-in once-per-node visitation).
"""

node Employee {
    has name: str;
    has title: str;
}

edge ReportsTo: Employee --> Employee {}

"""Build the fixture org deterministically; returns the CEO."""
def build_org() -> Employee {
    root ++> (ceo := Employee(name="Morgan", title="CEO"));
    root ++> (vp_eng := Employee(name="Lee", title="VP Eng"));
    root ++> (vp_sales := Employee(name="Pat", title="VP Sales"));
    root ++> (dev1 := Employee(name="Sasha", title="Dev"));
    root ++> (dev2 := Employee(name="Jamie", title="Dev"));
    root ++> (acct := Employee(name="Casey", title="Acct"));
    dev1 +>:ReportsTo:+> vp_eng;
    dev2 +>:ReportsTo:+> vp_eng;
    acct +>:ReportsTo:+> vp_sales;
    vp_eng +>:ReportsTo:+> ceo;
    vp_sales +>:ReportsTo:+> ceo;
    return ceo;
}

"""Add an employee under `manager` (None for the CEO); return them."""
def hire(manager: Employee | None, name: str, title: str) -> Employee {
    root ++> (emp := Employee(name=name, title=title));
    if manager is not None {
        emp +>:ReportsTo:+> manager;
    }
    return emp;
}

walker ChainClimb {
    """Climbs ReportsTo edges toward the CEO; linear, so list state is safe."""
    has stops: list[str] = [];
    has claimed: dict[str, bool] = {};

    can climb with Employee entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.stops.append(here.title);
        visit [->:ReportsTo:->] else { report self.stops; disengage; }
    }
}

walker TeamTally {
    """Descends reports; exit folds headcounts into a walker-side tally."""
    has claimed: dict[str, bool] = {};
    has tally: dict[str, int] = {};    # name -> subtree headcount

    can descend with Employee entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        visit [<-:ReportsTo:<-];
    }

    can fold with Employee exit {
        # Children always exit before their parent (reverse entry order),
        # so every child's tally is already recorded here.
        total = 1;
        for r in [<-:ReportsTo:<-] {
            total += self.tally[r.name];
        }
        self.tally[here.name] = total;
    }
}

walker DepthTally {
    """Descends reports; exit folds line depths into a walker-side tally."""
    has claimed: dict[str, bool] = {};
    has depths: dict[str, int] = {};   # name -> deepest line below, counting self

    can descend with Employee entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        visit [<-:ReportsTo:<-];
    }

    can fold with Employee exit {
        best = 0;
        for r in [<-:ReportsTo:<-] {
            if self.depths[r.name] > best {
                best = self.depths[r.name];
            }
        }
        self.depths[here.name] = best + 1;
    }
}

walker TitleSweep {
    """Collects title matches on walker fields, folded at exit by name."""
    has want: str;
    has claimed: dict[str, bool] = {};
    has hits_by: dict[str, list[str]] = {};   # name -> matches at/below

    can sweep with Employee entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        visit [<-:ReportsTo:<-];
    }

    can gather with Employee exit {
        hits = [here.title] if here.title == self.want else [];
        for r in [<-:ReportsTo:<-] {
            hits += self.hits_by[r.name];
        }
        self.hits_by[here.name] = hits;
    }
}

"""Titles of managers above `emp`, nearest manager first."""
def management_chain(emp: Employee) -> list[str] {
    w = emp spawn ChainClimb();
    return w.stops[1:];
}

"""Headcount of `emp`'s subtree, including themselves."""
def team_size(emp: Employee) -> int {
    w = emp spawn TeamTally();
    return w.tally[emp.name];
}

"""Length of the longest reporting line below `emp`, counting them."""
def org_depth(emp: Employee) -> int {
    w = emp spawn DepthTally();
    return w.depths[emp.name];
}

"""Every employee title match at or below `base`, sorted."""
def find_by_title(base: Employee, title: str) -> list[str] {
    w = base spawn TitleSweep(want=title);
    return sorted(w.hits_by[base.name]);
}
