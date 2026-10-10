"""Zephyr-style iterative join demo: persist a large immutable table and
re-join a changing frontier against it across K rounds without re-shuffling.

Models the core pain from issue #6997: a large static edge table
``DIR_EDGE`` is repeatedly joined against a small evolving frontier
across K dependent rounds of a driver loop. With no persistence, each
round pays the full read cost. A ``Persist`` walker simulates caching
the big table once, then ``DriverLoop`` repeatedly joins the frontier
against the resident dataset.
"""

# ---------- Edge archetypes ----------

edge PersistsAs {
    has storage_tier: str = "MEMORY_AND_DISK";
    has shards: int = 0;
    has evicted: bool = False;
}

edge JoinsAgainst {
    has round: int = 0;
    has scanned_bytes: int = 0;
    has probed_bytes: int = 0;
}

edge FrontierLink {
    has round: int = 0;
}

# ---------- Node archetypes ----------

node DirEdge {
    has src: str = "";
    has dst: str = "";
    has size_bytes: int = 0;
}

node Frontier {
    has label: str = "";
    has round: int = 0;
    has members: list[str] = [];
}

node CacheHandle {
    has name: str = "";
    has storage_tier: str = "MEMORY_AND_DISK";
    has shards: int = 0;
    has resident_bytes: int = 0;
    has pinned: bool = True;
    has evicted: bool = False;
}

# ---------- Walker: materialize + pin the big table once ----------

walker Persist {
    has handle_name: str = "DIR_EDGE_CACHE";
    has storage_tier: str = "MEMORY_AND_DISK";

    can start with Root entry {
        print(f"[persist] materializing {self.handle_name} tier={self.storage_tier}");
        visit [-->];
    }

    can ingest with DirEdge entry {
        # Each shard lands in the cache; we collapse all shards into one
        # resident handle to mirror "one logical table, many shards".
    }

    can finish with CacheHandle entry {
        self.handle = here;
    }
}

# ---------- Walker: simulate the K-round driver loop ----------

walker DriverLoop {
    has rounds: int = 3;
    has frontier: Frontier = Frontier(label="f0", round=0,
                                       members=["a", "b", "c"]);
    has cache: CacheHandle = None;
    has total_scanned: int = 0;
    has total_probed: int = 0;

    can start with Root entry {
        self.frontier = Frontier(label="f0", round=0,
                                  members=["a", "b", "c"]);
        # Materialize DIR_EDGE once (K x reads -> 1 x read).
        root spawn Persist(handle_name="DIR_EDGE_CACHE",
                           storage_tier="MEMORY_AND_DISK");
        # Bind the resulting cache handle back onto the driver.
        self.cache = [root-->->:CacheHandle:->][0] if (root-->->:CacheHandle:->) else None;
        visit [-->];
    }

    can drive with CacheHandle entry {
        for k in range(self.rounds) {
            self.frontier.round = k;
            new_members: list[str] = [];
            for m in self.frontier.members {
                new_members.append(m + str(k));
            }
            self.frontier.members = new_members;
            # Without cache: scanned_bytes == resident_bytes each round.
            # With cache: only probed_bytes per round matter.
            scanned = 0 if self.cache.pinned else self.cache.resident_bytes;
            probed = len(self.frontier.members) * 4;
            self.total_scanned += scanned;
            self.total_probed += probed;
            print(f"[round {k}] frontier={self.frontier.members} "
                  f"scanned={scanned}B probed={probed}B "
                  f"cache.pinned={self.cache.pinned}");
            visit [-->];
        }
        # Release the cached dataset after the loop ends.
        self.cache.evicted = True;
        self.cache.pinned = False;
        disengage;
    }

    can note with DirEdge entry {
        # DriverLoop visits the big table for inspection; in a real
        # engine the join would stream against the cached handle.
    }
}

with entry {
    # Build DIR_EDGE as a connected chain of shards off root.
    root ++> DirEdge(src="a", dst="x", size_bytes=10_000)
         ++> DirEdge(src="b", dst="y", size_bytes=10_000)
         ++> DirEdge(src="c", dst="z", size_bytes=10_000)
         ++> DirEdge(src="x", dst="p", size_bytes=10_000)
         ++> DirEdge(src="y", dst="q", size_bytes=10_000)
         ++> DirEdge(src="z", dst="r", size_bytes=10_000);

    # One CacheHandle node holds the resident materialized state.
    root ++> CacheHandle(name="DIR_EDGE_CACHE",
                         storage_tier="MEMORY_AND_DISK",
                         shards=6,
                         resident_bytes=60_000,
                         pinned=True,
                         evicted=False);

    driver = DriverLoop(rounds=3);
    root spawn driver;
    print(f"driver totals: scanned={driver.total_scanned}B "
          f"probed={driver.total_probed}B "
          f"cache.evicted={driver.cache.evicted}");
}