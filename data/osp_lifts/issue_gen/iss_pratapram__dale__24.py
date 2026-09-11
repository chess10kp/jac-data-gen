"""Entity resolution: transitive connectivity over shared attributes.

Accounts are linked *transitively* through shared attribute values
(shared email, shared phone): records sharing a value in ANY link field
belong to one entity. The resolver buckets records by ``(field, value)``,
expands the buckets into an adjacency map, and floods each component;
each record is tagged with its entity id. Blank or missing link values
must NEVER merge two records -- absence of an email is not a shared
email. Entity id = smallest record id in the component.
Ref: pratapram/dale#24
"""


def resolve_entities(records, link_fields):
    """``records``: dicts with an ``id`` key. Returns {record_id: entity_id}."""
    buckets = {}
    for rec in records:
        for field in link_fields:
            value = rec.get(field)
            if value is None or value == "":
                continue  # blank values never merge
            key = (field, value)
            if key not in buckets:
                buckets[key] = []
            buckets[key].append(rec["id"])

    adj = {rec["id"]: [] for rec in records}
    for ids in buckets.values():
        for a in ids:
            for b in ids:
                if a != b:
                    adj[a].append(b)

    label = {}
    for rec in records:
        rid = rec["id"]
        if rid in label:
            continue
        # flood the whole component; entity id = min member id
        comp = []
        seen = {rid}
        stack = [rid]
        while stack:
            cur = stack.pop()
            comp.append(cur)
            for nxt in adj[cur]:
                if nxt not in seen:
                    seen.add(nxt)
                    stack.append(nxt)
        entity = min(comp)
        for member in comp:
            label[member] = entity
    return label
