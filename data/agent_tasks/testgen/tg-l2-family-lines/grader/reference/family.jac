"""Family tree: Person nodes joined by ParentOf edges."""

node Person {
    has name: str;
    has born: int = 0;
}

edge ParentOf: Person --> Person {}

walker Descendants {
    has found: dict[str, int] = {};
    has origin: str = "";

    can down with Person entry {
        if self.origin == "" {
            self.origin = here.name;
        } elif here.name in self.found {
            skip;
        } else {
            self.found[here.name] = here.born;
        }
        visit [here ->:ParentOf:->];
    }

    can finish with exit {
        pairs = sorted([(b, n) for (n, b) in self.found.items()]);
        report [n for (_, n) in pairs];
    }
}

walker Ancestors {
    has found: list[str] = [];
    has origin: str = "";

    can up with Person entry {
        if self.origin == "" {
            self.origin = here.name;
        } elif here.name in self.found {
            skip;
        } else {
            self.found.append(here.name);
        }
        visit [here <-:ParentOf:<-];
    }

    can finish with exit {
        report sorted(self.found);
    }
}

walker FirstCousins {
    can find with Person entry {
        siblings = [s.name for s in [here <-:ParentOf:<- ->:ParentOf:->]];
        grandkids = [here <-:ParentOf:<- <-:ParentOf:<- ->:ParentOf:-> ->:ParentOf:->];
        cousins = {c.name for c in grandkids if c.name not in siblings and c.name != here.name};
        report sorted(cousins);
    }
}
