"""Taxonomy normalization OSP lift — powerslave94/botanicapp#51."""

node Taxa {
    has tid: str;
    has name: str;
    has rank: str;
    has is_accepted: bool = True;
}

node Plant {
    has pid: str;
    has name: str;
}

edge Parent {}
edge Synonym {}
edge PlantTaxa {}

obj TaxonomyIndex {
    has by_tid: dict[str, Taxa] = {};
    has plants: dict[str, Plant] = {};
}

walker ResolveWalker {
    has claimed: dict[str, bool] = {};
    has result_tid: str = "";
    can chase with Taxa entry {
        print("resolve", here.tid);
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        nxt: list[Taxa] = [here ->:Synonym:->][?:Taxa];
        if len(nxt) > 0 {
            visit :0: nxt;
        } else {
            self.result_tid = here.tid;
            disengage;
        }
    }
}

walker DescendantWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can descend with Taxa entry {
        print("descend", here.tid);
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        self.found.append(here.tid);
        kids: list[Taxa] = [here <-:Parent:<-][?:Taxa];
        visit :0: kids;
    }
}

walker SynonymClusterWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can gather with Taxa entry {
        print("synonym", here.tid);
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        self.found.append(here.tid);
        nbrs: list[Taxa] = [];
        rev: list[Taxa] = [here <-:Synonym:<-][?:Taxa];
        fwd: list[Taxa] = [here ->:Synonym:->][?:Taxa];
        for r in rev {
            nbrs.append(r);
        }
        for f in fwd {
            nbrs.append(f);
        }
        visit :0: nbrs;
    }
}

def bootstrap() -> tuple[Taxa, TaxonomyIndex] {
    graph_root: Taxa = Taxa(tid="__root__", name="root", rank="root", is_accepted=True);
    idx: TaxonomyIndex = TaxonomyIndex(by_tid={}, plants={});
    idx.by_tid["__root__"] = graph_root;
    return (graph_root, idx);
}

def register_taxon(
    idx: TaxonomyIndex,
    graph_root: Taxa,
    parent_tid: str,
    tid: str,
    name: str,
    rank: str,
    is_accepted: bool
) -> Taxa {
    if tid not in idx.by_tid {
        parent = idx.by_tid[parent_tid];
        nd = Taxa(tid=tid, name=name, rank=rank, is_accepted=is_accepted);
        nd +>:Parent:+> parent;
        graph_root ++> nd;
        idx.by_tid[tid] = nd;
    }
    return idx.by_tid[tid];
}

def link_synonym(idx: TaxonomyIndex, synonym_tid: str, accepted_tid: str) -> None {
    if synonym_tid in idx.by_tid {
        if accepted_tid in idx.by_tid {
            syn = idx.by_tid[synonym_tid];
            acc = idx.by_tid[accepted_tid];
            syn +>:Synonym:+> acc;
        }
    }
}

def register_plant(idx: TaxonomyIndex, graph_root: Taxa, pid: str, name: str, taxa_tid: str) -> Plant {
    pl = Plant(pid=pid, name=name);
    if taxa_tid in idx.by_tid {
        tx = idx.by_tid[taxa_tid];
        pl +>:PlantTaxa:+> tx;
    }
    graph_root ++> pl;
    idx.plants[pid] = pl;
    return pl;
}

def resolve_accepted(idx: TaxonomyIndex, tid: str) -> str {
    if tid not in idx.by_tid {
        return tid;
    }
    start = idx.by_tid[tid];
    w = start spawn ResolveWalker(claimed={});
    if w.result_tid == "" {
        return tid;
    }
    return w.result_tid;
}

def list_descendants(idx: TaxonomyIndex, tid: str) -> list[str] {
    if tid not in idx.by_tid {
        return [];
    }
    start = idx.by_tid[tid];
    w = start spawn DescendantWalker(claimed={});
    out: list[str] = [];
    for x in w.found {
        out.append(x);
    }
    return sorted(out);
}

def list_synonyms(idx: TaxonomyIndex, tid: str) -> list[str] {
    if tid not in idx.by_tid {
        return [];
    }
    start = idx.by_tid[tid];
    w = start spawn SynonymClusterWalker(claimed={});
    out: list[str] = [];
    for x in w.found {
        out.append(x);
    }
    return sorted(out);
}

def plants_for_taxon(idx: TaxonomyIndex, tid: str) -> list[str] {
    acc = resolve_accepted(idx, tid);
    out: list[str] = [];
    for pid in idx.plants {
        pl = idx.plants[pid];
        links: list[Taxa] = [pl ->:PlantTaxa:->][?:Taxa];
        if len(links) > 0 {
            if links[0].tid == acc {
                out.append(pid);
            }
        }
    }
    return sorted(out);
}

with entry {
    graph_root: Taxa;
    idx: TaxonomyIndex;
    (graph_root, idx) = bootstrap();
    register_taxon(idx, graph_root, "__root__", "fam1", "Rosaceae", "family", True);
    graph_root spawn DescendantWalker(claimed={});
}

test "descendants_sorted" {
    graph_root: Taxa;
    idx: TaxonomyIndex;
    (graph_root, idx) = bootstrap();
    register_taxon(idx, graph_root, "__root__", "fam1", "Rosaceae", "family", True);
    register_taxon(idx, graph_root, "fam1", "gen1", "Rosa", "genus", True);
    register_taxon(idx, graph_root, "fam1", "gen2", "Rubus", "genus", True);
    register_taxon(idx, graph_root, "gen1", "sp1", "Rosa canina", "species", True);
    ds = list_descendants(idx, "fam1");
    assert (ds == ["fam1", "gen1", "gen2", "sp1"]);
}

test "resolve_synonym_chain" {
    graph_root: Taxa;
    idx: TaxonomyIndex;
    (graph_root, idx) = bootstrap();
    register_taxon(idx, graph_root, "__root__", "acc1", "Accepted", "species", True);
    register_taxon(idx, graph_root, "__root__", "syn1", "Synonym A", "species", False);
    register_taxon(idx, graph_root, "__root__", "syn2", "Synonym B", "species", False);
    link_synonym(idx, "syn1", "acc1");
    link_synonym(idx, "syn2", "syn1");
    assert (resolve_accepted(idx, "syn2") == "acc1");
    assert (resolve_accepted(idx, "missing") == "missing");
}

test "synonym_cluster_sorted" {
    graph_root: Taxa;
    idx: TaxonomyIndex;
    (graph_root, idx) = bootstrap();
    register_taxon(idx, graph_root, "__root__", "acc1", "Accepted", "species", True);
    register_taxon(idx, graph_root, "__root__", "syn1", "Synonym A", "species", False);
    register_taxon(idx, graph_root, "__root__", "syn2", "Synonym B", "species", False);
    link_synonym(idx, "syn1", "acc1");
    link_synonym(idx, "syn2", "acc1");
    syns = list_synonyms(idx, "syn1");
    assert (syns == ["acc1", "syn1", "syn2"]);
}

test "plants_for_accepted_taxon" {
    graph_root: Taxa;
    idx: TaxonomyIndex;
    (graph_root, idx) = bootstrap();
    register_taxon(idx, graph_root, "__root__", "acc1", "Accepted", "species", True);
    register_plant(idx, graph_root, "p1", "Plant One", "acc1");
    register_plant(idx, graph_root, "p2", "Plant Two", "acc1");
    register_plant(idx, graph_root, "p3", "Plant Three", "missing");
    ps = plants_for_taxon(idx, "acc1");
    assert (ps == ["p1", "p2"]);
}

test "unknown_taxon_empty_lists" {
    graph_root: Taxa;
    idx: TaxonomyIndex;
    (graph_root, idx) = bootstrap();
    assert (list_descendants(idx, "nope") == []);
    assert (list_synonyms(idx, "nope") == []);
    assert (plants_for_taxon(idx, "nope") == []);
}
