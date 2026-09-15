"""LogicalPlan TreeNode walk/rewrite — apache/datafusion#10628."""

node ScanPlan {
  has cid: str;
  has table: str;
}

node FilterPlan {
  has cid: str;
  has predicate: str;
}

node ProjectPlan {
  has cid: str;
  has exprs: list[str] = [];
}

node GraphAnchor {
  has cid: str = "anchor";
}

edge Child {}

walker FindTableWalker {
  has claimed: dict[str, bool] = {};
  has found: str = "";

  can find_project with ProjectPlan entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    nxt: list[FilterPlan] = [];
    for ch in [here ->:Child:->][?:FilterPlan] { nxt.append(ch); }
    for ch in [here ->:Child:->][?:ScanPlan] {
      if self.found == "" { self.found = ch.table; }
    }
    visit :0: nxt else { disengage; }
    print("apply project", here.cid);
  }

  can find_filter with FilterPlan entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    nxt: list[ScanPlan | FilterPlan] = [];
    for ch in [here ->:Child:->][?:ScanPlan] { nxt.append(ch); }
    for ch in [here ->:Child:->][?:FilterPlan] { nxt.append(ch); }
    visit :0: nxt else { disengage; }
    print("apply filter", here.cid);
  }

  can find_scan with ScanPlan entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    if self.found == "" { self.found = here.table; }
    print("apply scan", here.table);
  }
}

walker RewriteWalker {
  has claimed: dict[str, bool] = {};
  has out_proj: ProjectPlan;

  can rewrite_project with ProjectPlan entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    child_scan: ScanPlan | None = None;
    for ch in [here ->:Child:->][?:FilterPlan] {
      gc_list: list[ScanPlan] = [];
      for gc in [ch ->:Child:->][?:ScanPlan] { gc_list.append(gc); }
      for gc in gc_list {
        child_scan = ScanPlan(cid=gc.cid, table=gc.table);
      }
    }
    for ch in [here ->:Child:->][?:ScanPlan] {
      child_scan = ScanPlan(cid=ch.cid, table=ch.table);
    }
    np = ProjectPlan(cid=here.cid, exprs=here.exprs);
    if child_scan is not None { np +>:Child:+> child_scan; }
    self.out_proj = np;
    print("rewrite project", here.cid);
  }
}

walker KindsWalker {
  has claimed: dict[str, bool] = {};
  has kinds: list[str] = [];

  can kind_project with ProjectPlan entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    nxt: list[ScanPlan | FilterPlan] = [];
    for ch in [here ->:Child:->][?:FilterPlan] { nxt.append(ch); }
    for ch in [here ->:Child:->][?:ScanPlan] { nxt.append(ch); }
    visit :0: nxt else { disengage; }
    self.kinds.append("Project");
    print("kind Project", here.cid);
  }

  can kind_filter with FilterPlan entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    nxt: list[ScanPlan | FilterPlan] = [];
    for ch in [here ->:Child:->][?:ScanPlan] { nxt.append(ch); }
    for ch in [here ->:Child:->][?:FilterPlan] { nxt.append(ch); }
    visit :0: nxt else { disengage; }
    self.kinds.append("Filter");
    print("kind Filter", here.cid);
  }

  can kind_scan with ScanPlan entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    self.kinds.append("Scan");
    print("kind Scan", here.cid);
  }
}

walker MainWalker {
  has claimed: dict[str, bool] = {};

  can open with GraphAnchor entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    nxt: list[ProjectPlan] = [];
    for ch in [here ->:Child:->][?:ProjectPlan] { nxt.append(ch); }
    visit :0: nxt else { disengage; }
    print("anchor open");
  }

  can demo with ProjectPlan entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    print("=== TreeNode apply/rewrite demo ===");
    t = apply_find_scan_table(here);
    print("scan table:", t);
    rw = rewrite_remove_filter(here);
    ks = collect_kinds_postorder(rw);
    print("post-rewrite kinds:", ks);
  }
}

def build_demo_plan -> ProjectPlan {
  scan = ScanPlan(cid="scan_orders", table="orders");
  filt = FilterPlan(cid="filt_active", predicate="active = true");
  proj = ProjectPlan(cid="proj_cols", exprs=["id", "name"]);
  anchor = GraphAnchor();
  root ++> anchor;
  anchor +>:Child:+> proj;
  proj +>:Child:+> filt;
  filt +>:Child:+> scan;
  return proj;
}

def apply_find_scan_table(root_node: ProjectPlan) -> str | None {
  w = root_node spawn FindTableWalker(claimed={});
  if w.found == "" { return None; }
  return w.found;
}

def rewrite_remove_filter(root_node: ProjectPlan) -> ProjectPlan {
  w = root_node spawn RewriteWalker(claimed={});
  return w.out_proj;
}

def collect_kinds_postorder(root_node: ProjectPlan) -> list[str] {
  w = root_node spawn KindsWalker(claimed={});
  return w.kinds;
}

with entry {
  build_demo_plan();
  root spawn MainWalker(claimed={});
}

test "find_scan_table" {
  proj = build_demo_plan();
  t = apply_find_scan_table(proj);
  assert t == "orders";
}

test "kinds_postorder_demo" {
  proj = build_demo_plan();
  ks = collect_kinds_postorder(proj);
  assert ks == ["Scan", "Filter", "Project"];
}

test "rewrite_removes_filter" {
  proj = build_demo_plan();
  rw = rewrite_remove_filter(proj);
  assert rw.cid == "proj_cols";
  assert rw.exprs == ["id", "name"];
  scans: list[ScanPlan] = [];
  for ch in [rw ->:Child:->][?:ScanPlan] { scans.append(ch); }
  assert len(scans) == 1;
  assert scans[0].table == "orders";
  filts: list[FilterPlan] = [];
  for ch in [rw ->:Child:->][?:FilterPlan] { filts.append(ch); }
  assert len(filts) == 0;
}

test "kinds_postorder_after_rewrite" {
  proj = build_demo_plan();
  rw = rewrite_remove_filter(proj);
  ks = collect_kinds_postorder(rw);
  assert ks == ["Scan", "Project"];
}

test "find_scan_none_on_empty_project" {
  empty_proj = ProjectPlan(cid="empty_proj", exprs=[]);
  t = apply_find_scan_table(empty_proj);
  assert t is None;
}
