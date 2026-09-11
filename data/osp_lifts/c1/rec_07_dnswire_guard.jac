"""DNS wire hierarchy lifted to OSP.

Domains are ``Domain`` nodes; ``PartOf`` edges point from a domain
to its parent zone. FQDN construction and zone chains climb; delegated
subdomain counts descend. Zone flags are payload the chain query
must respect.
"""

node Domain {
    has label: str;
    has is_zone: bool;
    has del_total: int = 0;  # staging: delegations below, folded at exit
}

edge PartOf: Domain --> Domain {}

"""Build the fixture zone tree deterministically; returns the root zone."""
def build_zones() -> Domain {
    root ++> (dns_root := Domain(label="", is_zone=True));
    root ++> (com := Domain(label="com", is_zone=True));
    root ++> (example := Domain(label="example", is_zone=True));
    root ++> (api := Domain(label="api", is_zone=False));
    root ++> (v1 := Domain(label="v1", is_zone=False));
    root ++> (org := Domain(label="org", is_zone=False));
    com +>:PartOf:+> dns_root;
    example +>:PartOf:+> com;
    api +>:PartOf:+> example;
    v1 +>:PartOf:+> api;
    org +>:PartOf:+> dns_root;
    return dns_root;
}

"""Delegate `label` under `parent` (None for the root zone); return it."""
def register(parent: Domain | None, label: str, is_zone: bool = False) -> Domain {
    root ++> (d := Domain(label=label, is_zone=is_zone));
    if parent is not None {
        d +>:PartOf:+> parent;
    }
    return d;
}

walker FqdnClimb {
    """Climbs PartOf edges to the root zone; linear walk."""
    has labels: list[str] = [];
    has zones: list[bool] = [];
    has claimed: dict[str, bool] = {};

    can climb with Domain entry {
        if here.label in self.claimed {
            skip;
        }
        self.claimed[here.label] = True;
        self.labels.append(here.label);
        self.zones.append(here.is_zone);
        visit [->:PartOf:->] else { report self.labels; disengage; }
    }
}

walker DelFold {
    """Exit folds strictly-below delegation counts bottom-up."""
    has claimed: dict[str, bool] = {};

    can descend with Domain entry {
        if here.label in self.claimed {
            skip;
        }
        self.claimed[here.label] = True;
        visit [<-:PartOf:<-];
    }

    can fold with Domain exit {
        total = 0;
        for s in [<-:PartOf:<-] {
            total += 1 + s.del_total;
        }
        here.del_total = total;
    }
}

"""Fully qualified name of `d`, built by ascending to the root."""
def fqdn(d: Domain) -> str {
    w = d spawn FqdnClimb();
    return "".join([lab + "." for lab in reversed(w.labels)]);
}

"""Zone names on the path to the root, nearest zone first."""
def zone_chain(d: Domain) -> list[str] {
    w = d spawn FqdnClimb();
    picked = [w.labels[i] for i in range(len(w.labels)) if w.zones[i]];
    return picked;
}

"""Delegated domains strictly below `zone`."""
def subdomain_count(zone: Domain) -> int {
    zone spawn DelFold();
    return zone.del_total;
}

"""Hops from `d` up to the nearest enclosing zone host (itself counts)."""
def soa_distance(d: Domain) -> int {
    w = d spawn FqdnClimb();
    for i in range(len(w.zones)) {
        if w.zones[i] {
            return i + 1;
        }
    }
    return -1;
}
test "fqdn assembles root-first labels" {
    dns_root = build_zones();
    com = [d for d in [dns_root <--][?:Domain] if d.label == "com"][0];
    example = [d for d in [com <--][?:Domain] if d.label == "example"][0];
    api = [d for d in [example <--][?:Domain]][0];
    v1 = [d for d in [api <--][?:Domain]][0];
    assert fqdn(v1) == ".com.example.api.v1.";
}

test "zone_chain respects zone flags" {
    dns_root = build_zones();
    com = [d for d in [dns_root <--][?:Domain] if d.label == "com"][0];
    example = [d for d in [com <--][?:Domain]][0];
    v1 = [d for d in [[example <--][?:Domain][0] <--][?:Domain]][0];
    org = [d for d in [dns_root <--][?:Domain] if d.label == "org"][0];
    assert zone_chain(v1) == ["example", "com", ""];
    assert zone_chain(org) == [""];
}

test "subdomain_count folds delegations" {
    dns_root = build_zones();
    com = [d for d in [dns_root <--][?:Domain] if d.label == "com"][0];
    assert subdomain_count(com) == 3;
}

test "soa_distance finds nearest zone host" {
    dns_root = build_zones();
    com = [d for d in [dns_root <--][?:Domain] if d.label == "com"][0];
    example = [d for d in [com <--][?:Domain]][0];
    v1 = [d for d in [[example <--][?:Domain][0] <--][?:Domain]][0];
    assert soa_distance(v1) == 3;
    assert soa_distance(example) == 1;
}
test "register delegates a subdomain" {
    dns_root = build_zones();
    com = [d for d in [dns_root <--][?:Domain] if d.label == "com"][0];
    example = [d for d in [com <--][?:Domain] if d.label == "example"][0];
    api = [d for d in [example <--][?:Domain]][0];
    assert subdomain_count(example) == 2;
    shop = register(example, "shop");
    assert fqdn(shop) == ".com.example.shop.";
    assert zone_chain(shop) == ["example", "com", ""];
    assert soa_distance(shop) == 2;
    assert subdomain_count(example) == 3;
}
