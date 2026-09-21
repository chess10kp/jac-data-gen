"""Archetype-level access policy: every instance of a type is open WRITE.

Some openness is an invariant of the *type*, not a per-instance choice.
My app keeps a machine-rebuilt docs cache; instead of remembering
`grant()` at every creation site, I define `__jac_access__` on the
archetype to return AccessLevel.WRITE. The runtime consults the hook
before stored grants whenever a non-owner touches an instance, and the
returned level is final -- grants are not even consulted. Subtypes
inherit the policy automatically.

(The owner and the system root always keep WRITE regardless of hooks;
this example matters in multi-user served runs via `jac start`.)
"""

node DocsCache {
    has topic: str = "";
    has payload: str = "";
    has rebuilt_at: int = 0;

    # Per-archetype invariant: any user may read AND overwrite any cache.
    def __jac_access__ -> AccessLevel {
        return AccessLevel.WRITE;
    }
}

node CachedEntry(DocsCache) { }  # inherits the open policy

edge CacheLink {
    def __jac_access__ -> AccessLevel {
        return AccessLevel.WRITE;  # pair open nodes with an open edge type
    }
}

walker rebuild_cache {
    has entries: dict[str, str];

    can run with Root entry {
        for (topic, payload) in self.entries.items() {
            here ++> DocsCache(topic=topic, payload=payload, rebuilt_at=1);
        }
        report {"rebuilt": len(self.entries)};
    }
}

walker list_cache {
    can run with Root entry {
        report [{"topic": c.topic, "bytes": len(c.payload)}
                for c in [-->][?:DocsCache]];
    }
}

with entry {
    root spawn rebuild_cache(entries={
        "walkers": "visit, report, disengage",
        "grants": "per-instance access policy",
    });

    listing = root spawn list_cache();
    print(listing.reports);
}
