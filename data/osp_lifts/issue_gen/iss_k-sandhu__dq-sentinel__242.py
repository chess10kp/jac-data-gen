"""BI lineage connector core: dataset-to-dashboard impact analysis.

k-sandhu/dq-sentinel#242: the lineage graph must not stop at the warehouse --
dashboards and workbooks built on top of datasets need an impact API so the
incident question "which reports are wrong?" is answerable. The in-memory
core keeps a dataset dependency map plus BI assets whose upstream table refs
are normalized and matched against known datasets (unmatched refs are
recorded, never silently dropped). Impact propagates from a dataset through
its transitive dependents to every asset matched onto them.
"""


def normalize_table_ref(db, schema, table):
    """Canonical ``db.schema.table`` reference, lower-cased."""
    return "{}.{}.{}".format(
        str(db).strip().lower(), str(schema).strip().lower(),
        str(table).strip().lower(),
    )


def build_catalog(datasets, dataset_deps, assets):
    """Catalog dict from declared datasets, (dependent, upstream) dataset
    pairs, and (external_id, kind, name, [raw_refs]) assets."""
    cat = {
        "datasets": sorted(datasets),
        "deps": {},          # dataset -> [upstream datasets]
        "assets": {},        # external_id -> {"kind", "name", "refs"}
        "matches": {},       # external_id -> [(normalized_ref, matched)]
    }
    for d in datasets:
        cat["deps"][d] = []
    for dependent, upstream in dataset_deps:
        if dependent in cat["deps"] and upstream in cat["deps"]:
            cat["deps"][dependent].append(upstream)
    for external_id, kind, name, raw_refs in assets:
        cat["assets"][external_id] = {
            "kind": kind,
            "name": name,
            "refs": [normalize_table_ref(*r) for r in raw_refs],
        }
    _match_assets(cat)
    return cat


def _match_assets(cat):
    """Bind each normalized asset ref to a dataset where one exists."""
    for external_id in sorted(cat["assets"]):
        info = cat["assets"][external_id]
        pairs = []
        for ref in info["refs"]:
            pairs.append((ref, ref in cat["deps"]))
        cat["matches"][external_id] = pairs


def unmatched_refs(cat):
    """Sorted (external_id, raw_ref) pairs that matched no dataset."""
    out = []
    for external_id in sorted(cat["matches"]):
        for ref, matched in cat["matches"][external_id]:
            if not matched:
                out.append((external_id, ref))
    return out


def _dependents_closure(cat, dataset):
    """The dataset plus every dataset transitively built on it."""
    dependents = {}
    for dependent in cat["deps"]:
        for up in cat["deps"][dependent]:
            dependents.setdefault(up, []).append(dependent)
    seen = set()
    stack = [dataset]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        stack.extend(dependents.get(cur, []))
    return seen


def impacted_assets(cat, dataset):
    """Sorted external_ids of assets built on ``dataset`` or on any dataset
    transitively derived from it. Unknown datasets impact nothing."""
    if dataset not in cat["deps"]:
        return []
    blast = _dependents_closure(cat, dataset)
    hits = []
    for external_id in sorted(cat["matches"]):
        for ref, matched in cat["matches"][external_id]:
            if matched and ref in blast and external_id not in hits:
                hits.append(external_id)
    return hits
