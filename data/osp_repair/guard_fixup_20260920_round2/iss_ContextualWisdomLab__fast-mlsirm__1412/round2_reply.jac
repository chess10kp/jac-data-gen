The failure is a **persistence error**, not wrong envelope logic: `distance=1e999` becomes non-finite JSON (`Infinity`) when the graph is stored, so the walker never reaches your finite check. Sanitize non-finite distances in `Cell` **before** persistence, and have the walker fail closed using that flag.

```jac candidate
"""Residual interaction-map envelope: model cells, coordinates, and an envelope walker.

The issue complains about hand-rolled machinery in `fast_mlsirm.residual_interaction_map`:
closest/farthest cells, rank, coverage, residual equality, and the two-axis presentation
payload were all derived in a Python adapter. We model the essential scenario natively:

  * nodes for Person, Item, Cell, and Envelope (the validated Rust-owned result);
  * typed edges for retention, coordinate attachment, and provenance;
  * a walker that traverses retained cells, computes the envelope payload
    (closest/farthest with an explicit tie contract, coverage, rank, finite-value
    checks, schema version), and reports it once at exit.
"""

node Person {
    has pid: str = "";
    has coord_x: float = 0.0;
    has coord_y: float = 0.0;
}

node Item {
    has iid: str = "";
    has coord_x: float = 0.0;
    has coord_y: float = 0.0;
}

# A retained Cell holds observed, expected, residual, distance, reconstruction,
# unexplained, and cross-share values. All arithmetic fields are typed.
node Cell {
    has person_idx: int = 0;
    has item_idx: int = 0;
    has observed: float = 0.0;
    has expected: float = 0.0;
    has residual: float = 0.0;
    has distance: float = 0.0;
    has reconstruction: float = 0.0;
    has unexplained: float = 0.0;
    has cross_share: float = 0.0;
    has distance_non_finite: bool = False;

    can postinit {
        d = self.distance;
        if (d != d) or (d == 1e999) or (d == -1e999) or (d > 1e300) or (d < -1e300) {
            self.distance_non_finite = True;
            self.distance = 0.0;
        }
    }
}

# The validated envelope: schema version, algorithm id, implementation version,
# input digest, finite flag, and a single exit `report` payload.
node Envelope {
    has schema_version: int = 1;
    has algorithm_id: str = "fast-mlsirm.residual_interaction_map";
    has implementation_version: str = "0.1.0";
    has input_digest: str = "sha256:placeholder";
    has finite: bool = True;
    has axis_count: int = 0;
    has effective_rank: int = 0;
    has closest_cell: str = "";
    has farthest_cell: str = "";
    has scored_cells: int = 0;
    has map_cells: int = 0;
    has incomplete_persons: int = 0;
    has incomplete_items: int = 0;
}

# Empty relationship edges (relationship carries meaning via the type name).
edge RetainsCell { }
edge AnchorsPerson { }
edge AnchorsItem { }
edge ComputesEnvelope { }

walker EnvelopeBuilder {
    has requested_axes: int = 2;
    # Tie-break contract: deterministic by person_idx asc, then item_idx asc.
    # Scratch accumulators kept on the walker so the source logic survives.
    has finite_ok: bool = True;
    has max_dist: float = -1.0;
    has min_dist: float = -1.0;
    has max_key: str = "";
    has min_key: str = "";
    has scored: int = 0;
    has mapped: int = 0;
    has reports: list = [];

    can start with Root entry {
        visit [->:AnchorsPerson:->];
    }

    can pass_person with Person entry {
        for cell in [->:RetainsCell:->] {
            if cell.distance_non_finite {
                self.finite_ok = False;
                self.reports.append(
                    {
                        "schema_version": 1,
                        "ok": False,
                        "reason": "non-finite cell distance",
                        "person_idx": cell.person_idx,
                        "item_idx": cell.item_idx,
                    }
                );
                disengage;
            }
            d = cell.distance;
            # Finite-value check: non-finite is a hard failure per the schema contract.
            is_finite = (d == d) and (d != 1e999) and (d != -1e999);
            if not is_finite {
                self.finite_ok = False;
                self.reports.append(
                    {
                        "schema_version": 1,
                        "ok": False,
                        "reason": "non-finite cell distance",
                        "person_idx": cell.person_idx,
                        "item_idx": cell.item_idx,
                    }
                );
                disengage;
            }
            self.scored += 1;
            self.mapped += 1;
            key = f"{cell.person_idx}:{cell.item_idx}";
            # Tie contract: smaller distance wins; on equal distance, smaller key wins.
            is_closer = (self.min_dist < 0.0) or (d < self.min_dist) or (d == self.min_dist and key < self.min_key);
            if is_closer {
                self.min_dist = d;
                self.min_key = key;
            }
            is_farther = (self.max_dist < 0.0) or (d > self.max_dist) or (d == self.max_dist and key < self.max_key);
            if is_farther {
                self.max_dist = d;
                self.max_key = key;
            }
        }
    }

    can pass_item with Item entry {
        visit [-->];
    }
}

with entry {
    # Build two persons, two items, three retained cells, and an empty envelope.
    p1 = Person(pid="p1", coord_x=1.0, coord_y=2.0);
    p2 = Person(pid="p2", coord_x=3.0, coord_y=4.0);
    i1 = Item(iid="i1", coord_x=0.5, coord_y=0.5);
    i2 = Item(iid="i2", coord_x=1.5, coord_y=1.5);

    c1 = Cell(person_idx=0, item_idx=0, observed=1.0, expected=0.5, residual=0.5,
              distance=0.25, reconstruction=0.75, unexplained=0.25, cross_share=0.1);
    c2 = Cell(person_idx=0, item_idx=1, observed=2.0, expected=1.0, residual=1.0,
              distance=1.00, reconstruction=1.50, unexplained=0.50, cross_share=0.2);
    c3 = Cell(person_idx=1, item_idx=1, observed=3.0, expected=2.0, residual=1.0,
              distance=2.00, reconstruction=2.00, unexplained=1.00, cross_share=0.3);

    env = Envelope(schema_version=1, axis_count=2, effective_rank=2);

    # Wire the graph with typed edges where the relationship carries meaning.
    root +>:AnchorsPerson:+> p1;
    root +>:AnchorsPerson:+> p2;
    root +>:AnchorsItem:+> i1;
    root +>:AnchorsItem:+> i2;
    p1 +>:RetainsCell:+> c1;
    p1 +>:RetainsCell:+> c2;
    p2 +>:RetainsCell:+> c3;
    p1 +>:ComputesEnvelope:+> env;

    # Spawn the walker; it will traverse persons/items/cells and build the envelope.
    builder = EnvelopeBuilder(requested_axes=2);
    root spawn builder;

    # Apply results to the envelope node and print the validated payload.
    env.closest_cell = builder.min_key;
    env.farthest_cell = builder.max_key;
    env.scored_cells = builder.scored;
    env.map_cells = builder.mapped;
    env.finite = builder.finite_ok;
    env.incomplete_persons = 0;
    env.incomplete_items = 0;

    print(f"schema_version={env.schema_version} algorithm={env.algorithm_id} "
          f"impl={env.implementation_version}");
    print(f"requested_axes={builder.requested_axes} effective_rank={env.effective_rank} "
          f"finite={env.finite}");
    print(f"closest={env.closest_cell} farthest={env.farthest_cell} "
          f"scored={env.scored_cells} mapped={env.map_cells} "
          f"incomplete_persons={env.incomplete_persons} "
          f"incomplete_items={env.incomplete_items}");
}
```

```jac tests
unchanged
```

**What changed**

1. **`Cell.distance_non_finite` + `can postinit`** — Detects NaN, ±1e999, and overflowed magnitudes (`> 1e300`), sets the flag, and stores `0.0` so JSON persistence never sees `Infinity`.
2. **`pass_person` early guard** — Checks `cell.distance_non_finite` before scoring; emits the schema report and `disengage`s with `scored == 0` and `mapped == 0`, matching the test contract.

The other four tests were already passing; this targets only the `PgWireError` on the non-finite case. Switch to **Agent mode** if you want this applied directly in the workspace.