"""DiagramCraft/diagram-craft#2027 — impact analysis overlay on the canvas."""

node Shape {
    has cid: str;
    has entity_id: str = "";
    has impact: bool = False;
    has cycle: bool = False;
}

edge Drawn {}
edge Catalog {}

obj Diagram {
    has nodes: dict[str, Shape] = {};
    has graph_root: Shape | None = None;
}

walker ImpactWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has depth_by_id: dict[str, int] = {};
    has upstream: bool = False;
    has max_depth: int = -1;
    has model_aware: bool = False;

    can step with Shape entry {
        print(here.cid);
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if self.max_depth < 0 or self.depth_by_id[here.cid] <= self.max_depth {
            self.found.append(here.cid);
        }
        if self.max_depth >= 0 and self.depth_by_id[here.cid] >= self.max_depth {
            skip;
        }
        if self.upstream and self.model_aware {
            for kid in [here <-:Drawn:<-][?:Shape] {
                if kid.cid not in self.depth_by_id {
                    self.depth_by_id[kid.cid] = self.depth_by_id[here.cid] + 1;
                }
                visit :0: [kid];
            }
            for kid in [here <-:Catalog:<-][?:Shape] {
                if kid.cid not in self.depth_by_id {
                    self.depth_by_id[kid.cid] = self.depth_by_id[here.cid] + 1;
                }
                visit :0: [kid];
            }
        } elif self.upstream {
            for kid in [here <-:Drawn:<-][?:Shape] {
                if kid.cid not in self.depth_by_id {
                    self.depth_by_id[kid.cid] = self.depth_by_id[here.cid] + 1;
                }
                visit :0: [kid];
            }
        } elif self.model_aware {
            for kid in [here ->:Drawn:->][?:Shape] {
                if kid.cid not in self.depth_by_id {
                    self.depth_by_id[kid.cid] = self.depth_by_id[here.cid] + 1;
                }
                visit :0: [kid];
            }
            for kid in [here ->:Catalog:->][?:Shape] {
                if kid.cid not in self.depth_by_id {
                    self.depth_by_id[kid.cid] = self.depth_by_id[here.cid] + 1;
                }
                visit :0: [kid];
            }
        } else {
            for kid in [here ->:Drawn:->][?:Shape] {
                if kid.cid not in self.depth_by_id {
                    self.depth_by_id[kid.cid] = self.depth_by_id[here.cid] + 1;
                }
                visit :0: [kid];
            }
        }
    }
}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has found: bool = False;
    has model_aware: bool = False;

    can trace with Shape entry {
        print(here.cid);
        if here.cid in self.claimed {
            if here.cid == self.target {
                self.found = True;
            }
            skip;
        }
        self.claimed[here.cid] = True;
        for kid in [here ->:Drawn:->][?:Shape] {
            visit :0: [kid];
        }
        if self.model_aware {
            for kid in [here ->:Catalog:->][?:Shape] {
                visit :0: [kid];
            }
        }
    }
}

def build_diagram(
    node_ids: list[str],
    drawn_edges: list[list[str]],
    entity_ids: dict[str, str] | None = None,
    catalog_edges: list[list[str]] | None = None
) -> Diagram {
    diagram = Diagram();
    for ident in node_ids {
        if ident not in diagram.nodes {
            shape = Shape(cid=ident);
            if entity_ids != None and ident in entity_ids {
                shape.entity_id = entity_ids[ident];
            }
            diagram.nodes[ident] = shape;
            if diagram.graph_root == None {
                diagram.graph_root = shape;
            }
        }
    }
    for link in drawn_edges {
        if len(link) >= 2 and link[0] in diagram.nodes and link[1] in diagram.nodes {
            src = diagram.nodes[link[0]];
            dst = diagram.nodes[link[1]];
            src +>:Drawn:+> dst;
        }
    }
    if catalog_edges != None {
        for link in catalog_edges {
            if len(link) >= 2 and link[0] in diagram.nodes and link[1] in diagram.nodes {
                src = diagram.nodes[link[0]];
                dst = diagram.nodes[link[1]];
                src +>:Catalog:+> dst;
            }
        }
    }
    return diagram;
}

def impact_overlay(
    diagram: Diagram,
    selected: list[str],
    upstream: bool = False,
    depth: int = -1,
    model_aware: bool = False
) -> list[str] {
    result: list[str] = [];
    for ident in diagram.nodes {
        diagram.nodes[ident].impact = False;
    }
    for ident in selected {
        if ident in diagram.nodes {
            shape = diagram.nodes[ident];
            w = shape spawn ImpactWalk(
                upstream=upstream,
                max_depth=depth,
                model_aware=model_aware
            );
            w.depth_by_id[ident] = 0;
            for found_id in w.found {
                if not diagram.nodes[found_id].impact {
                    diagram.nodes[found_id].impact = True;
                    result.append(found_id);
                }
            }
        }
    }
    return sorted(result);
}

def cycle_overlay(
    diagram: Diagram,
    model_aware: bool = False
) -> list[str] {
    result: list[str] = [];
    for ident in diagram.nodes {
        diagram.nodes[ident].cycle = False;
    }
    for ident in sorted(diagram.nodes) {
        shape = diagram.nodes[ident];
        w = shape spawn CycleProbe(
            target=ident,
            model_aware=model_aware
        );
        if w.found {
            shape.cycle = True;
            result.append(ident);
        }
    }
    return sorted(result);
}
