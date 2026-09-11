"""BI lineage connector core: dataset-to-dashboard impact analysis.

k-sandhu/dq-sentinel#242 lifted to OSP: warehouse datasets become Dataset
archetypes, BI dashboards/workbooks become BiAsset archetypes, and asset
upstream table refs become typed BuiltOn edges (matched flag as payload,
unmatched refs reported on the handle and never silently dropped). Dataset
lineage becomes mirrored typed feeds edges so impact propagation from a
dataset through its transitive dependents stays walker-native.
"""
node Dataset {
    has fq_name: str;
}
node BiAsset {
    has external_id: str;
    has kind: str;
    has display_name: str;
}
edge BuiltOn {
    has raw_ref: str;
}
edge FeedsInto {}

"""Catalog handle: names resolve through these lookup maps."""
obj Catalog {
    has datasets: dict[str, Dataset];
    has assets: dict[str, BiAsset];
    has unmatched: list[tuple] = [];

    def resolve_dataset(name: str) -> Dataset | None {
        return self.datasets.get(name);
    }

    def dataset_names() -> list[str] {
        out: list[str] = [];
        for k in self.datasets.keys() {
            out.append(k);
        }
        return sorted(out);
    }
}

# Canonical ``db.schema.table`` reference, lower-cased.
def normalize_table_ref(db: str, schema: str, table: str) -> str {
    a = str(db).strip();
    b = str(schema).strip();
    c = str(table).strip();
    whole = a + "." + b + "." + c;
    return whole.lower();
}

walker AssetFeedsFlood {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_name: str = "";

    can step with Dataset entry {
        if here.fq_name in self.claimed {
            skip;
        }
        if here.fq_name != self.start_name {
            self.reached.append(here.fq_name);
        }
        self.claimed[here.fq_name] = True;
        visit [->:FeedsInto:->];
    }
}

def build_catalog(datasets: list[str], dataset_deps: list[tuple[str, str]],
                  assets: list[tuple[str, str, str, list[tuple]]]) -> Catalog {
    cat = Catalog(datasets={}, assets={});
    for d in datasets {
        n = Dataset(fq_name=d);
        root ++> n;
        cat.datasets[d] = n;
    }
    for (dependent, upstream) in dataset_deps {
        a = cat.datasets.get(dependent);
        b = cat.datasets.get(upstream);
        if a is not None and b is not None {
            b +>:FeedsInto:+> a;
        }
    }
    for (external_id, kind, name, raw_refs) in assets {
        bi = BiAsset(external_id=external_id, kind=kind, display_name=name);
        root ++> bi;
        cat.assets[external_id] = bi;
        for raw in raw_refs {
            ref = normalize_table_ref(raw[0], raw[1], raw[2]);
            ds = cat.datasets.get(ref);
            if ds is None {
                cat.unmatched.append((external_id, ref));
            } else {
                bi +>:BuiltOn(raw_ref=ref):+> ds;
            }
        }
    }
    return cat;
}

"""Sorted (external_id, raw_ref) pairs that matched no dataset."""
def unmatched_refs(cat: Catalog) -> list[tuple] {
    return sorted(cat.unmatched);
}

"""Sorted external_ids built on ``dataset`` or its transitive derivatives."""
def impacted_assets(cat: Catalog, dataset: str) -> list[str] {
    start = cat.resolve_dataset(dataset);
    if start is None {
        return [];
    }
    w = start spawn AssetFeedsFlood(start_name=dataset);
    blast = w.reached + [dataset];

    hits: list[str] = [];
    for eid in sorted(cat.assets.keys()) {
        a = cat.assets[eid];
        outs = [a ->:BuiltOn:->];
        impacted = False;
        for ds in outs {
            for bname in blast {
                if ds.fq_name == bname {
                    impacted = True;
                }
            }
        }
        if impacted {
            hits.append(eid);
        }
    }
    return hits;
}
