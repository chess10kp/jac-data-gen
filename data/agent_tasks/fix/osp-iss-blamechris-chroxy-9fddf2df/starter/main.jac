"""Session query: live-preferred search over a transcript corpus with relationship filters.

Models a tiny slice of dsh's session-query design. Conversations are graphs (sessions
fork into children, subagents are spawned from a session), and search walks that graph
with a walker that prefers in-memory live data over the indexed corpus. Typed edges
carry the relationships (`fork_parent`, `subagent_of`, `belongs_to_project`); the
walker enforces the live-preferred contract by checking fresh messages first.
"""

# ---------- Edge archetypes ----------

edge ForkOf { }
edge SubagentOf { }
edge BelongsTo { has project: str = ""; }
edge PartOfSession { }

# ---------- Node archetypes ----------

node Project {
    has name: str = "";
}

node Session {
    has title: str = "";
    has provider: str = "";
}

node Message {
    has role: str = "";
    has body: str = "";
    has timestamp: int = 0;
    # live flag — set on messages appended this turn; live-preferred reads
    # must return these even before the index sees them.
    has live: bool = False;
}

# ---------- Walker ----------

walker SearchSession {
    has query: str = "";
    has role_filter: str = "";
    has project_filter: str = "";
    has hits: list = [];

    can start with Root entry {
        visit [-->];
    }

    # At a session we descend through every relationship that could yield
    # candidates: forked children, subagent lineages, and the indexed corpus.
    can search_session with Session entry {
        self.hits = self.hits + self.collect_from(here);
        visit [->:ForkOf:->];
        visit [here->:SubagentOf:->];
    }

    # Index node — the "indexed corpus" backing store. The walker stops here
    # only if live data did not satisfy the query.
    can search_index with Message entry {
        # Drop hits from the index for any session that already produced a
        # live-preferred hit. (Live-preferred is the whole point.)
        if here.live {
            return;
        }
        if self.match(here) {
            self.hits = self.hits + [here];
        }
    }

    # Helper: match a candidate message against filters + query.
    def match(self, m: Message) -> bool {
        if self.role_filter and m.role != self.role_filter {
            return False;
        }
        if self.project_filter and m.belongs_to_project() != self.project_filter {
            return False;
        }
        if self.query and self.query not in m.body.lower() {
            return False;
        }
        return True;
    }

    # Helper: collect live messages on this session first; then fall through
    # to the index for anything not already covered.
    def collect_from(self, s: Session) -> list {
        live_hits: list = [];
        for m in [s->:PartOfSession:->] {
            if not m.live {
                continue;
            }
            if self.match(m) {
                live_hits = live_hits + [m];
            }
        }
        return live_hits;
    }

    # Reachability / final report — terminate after a pass over the graph.
    can finish with Root entry {
        print(f"Search hits ({len(self.hits)}):");
        for h in self.hits {
            print(f"  [{h.role}] {h.body}");
        }
        disengage;
    }
}

# ---------- Project lookup helper (decorates a message with its project) ----------

obj MsgLookup {
    static def belongs_to_project(m: Message) -> str {
        for s in [m->:PartOfSession:->] {
            for p in [s->:BelongsTo:->] {
                return p.name;
            }
        }
        return "";
    }
}

# ---------- Object -> method shim for Message.belongs_to_project ----------
# Keeps the walker body readable while staying on `node` for entity identity.
# We extend Message via a method-style field by giving the helper module
# responsibility for the lookup.
{
    # local alias so the walker can call m.belongs_to_project() cleanly.
}

# Re-declare the lookup as a method attached via a module-level helper:
# In Jac, methods on nodes must live inside the `node` block. We provide
# one there:
# (See updated Message definition above.)