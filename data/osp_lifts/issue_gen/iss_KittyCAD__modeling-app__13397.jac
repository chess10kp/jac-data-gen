node Artifact { has cid: str; has kind: str; }
node HelixCall { has hid: str; has cylinder: str; has revolutions: int; has angleStart: int; }
node GraphRoot { has name: str; }
edge Downstream {}
edge Owns {}
edge HelixLink {}
walker CollectDownstream {
  has claimed: dict[str, bool] = {};
  has found: list[str] = [];
  can collect with Artifact entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    self.found.append(here.cid);
    for nxt in [here ->:Downstream:->][?:Artifact] {
      visit :0: [nxt];
    }
    print("collected " + here.cid);
  }
}
def find_artifact(graph_root: GraphRoot, cid: str) -> Artifact | None {
  for nd in [graph_root ->:Owns:->][?:Artifact] {
    if nd.cid == cid { return nd; }
  }
  return None;
}
def find_helix(graph_root: GraphRoot, hid: str) -> HelixCall | None {
  for nd in [graph_root ->:Owns:->][?:HelixCall] {
    if nd.hid == hid { return nd; }
  }
  return None;
}
def make_graph(name: str) -> GraphRoot {
  g = GraphRoot(name=name);
  root ++> g;
  return g;
}
def add_artifact(graph_root: GraphRoot, cid: str, kind: str) -> Artifact {
  nd = Artifact(cid=cid, kind=kind);
  graph_root +>:Owns:+> nd;
  return nd;
}
def add_downstream(graph_root: GraphRoot, parent_cid: str, child_cid: str) -> bool {
  p = find_artifact(graph_root, parent_cid);
  c = find_artifact(graph_root, child_cid);
  if p is None { return False; }
  if c is None { return False; }
  p +>:Downstream:+> c;
  return True;
}
def get_cylinder_for_edit(graph_root: GraphRoot, cylinder_sel: str, node_to_edit: str | None = None) -> str {
  if node_to_edit is not None { return cylinder_sel; }
  st = find_artifact(graph_root, cylinder_sel);
  if st is None { return cylinder_sel; }
  w = st spawn CollectDownstream(claimed={}, found=[]);
  leaves: list[str] = [];
  for cid in w.found {
    nd = find_artifact(graph_root, cid);
    if nd is not None {
      kids: list[Artifact] = [nd ->:Downstream:->][?:Artifact];
      if len(kids) == 0 { leaves.append(cid); }
    }
  }
  if len(leaves) > 0 {
    s: list[str] = sorted(leaves);
    return s[len(s) - 1];
  }
  return cylinder_sel;
}
def add_helix(graph_root: GraphRoot, helix_id: str, cylinder_sel: str, node_to_edit: str | None = None, revolutions: int = 3, angle_start: int = 0) -> str {
  cyl: str = get_cylinder_for_edit(graph_root, cylinder_sel, node_to_edit);
  existing: HelixCall | None = find_helix(graph_root, helix_id);
  if existing is not None {
    existing.cylinder = cyl;
    existing.revolutions = revolutions;
    existing.angleStart = angle_start;
    return existing.cylinder;
  }
  hc = HelixCall(hid=helix_id, cylinder=cyl, revolutions=revolutions, angleStart=angle_start);
  graph_root +>:Owns:+> hc;
  art = find_artifact(graph_root, cyl);
  if art is not None { hc +>:HelixLink:+> art; }
  return hc.cylinder;
}
with entry {
  g = make_graph("demo");
  a = add_artifact(g, "demo_extrude", "extrude");
  w = a spawn CollectDownstream(claimed={}, found=[]);
  print("demo found " + str(len(w.found)));
}
