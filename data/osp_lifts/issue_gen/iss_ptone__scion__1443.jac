"""ptone/scion#1443 — group hierarchy downward path and upward ancestor collection."""

node Group {
  has gid: str;
}

edge ChildGroups {}

walker PathDownW {
  has target: str;
  has max_depth: int;
  has claimed: dict[str, bool] = {};
  has depth: int = 0;
  has found: bool = False;

  can step with Group entry {
    if self.found {
      disengage;
    }
    if here.gid in self.claimed {
      skip;
    }
    self.claimed[here.gid] = True;
    if here.gid == self.target {
      self.found = True;
      print(here.gid);
      disengage;
    }
    if self.depth < self.max_depth {
      kids: list[Group] = [here ->:ChildGroups:->][?:Group];
      if kids {
        self.depth += 1;
        visit :0: kids;
      }
    }
  }
}

walker AncestorsW {
  has start_gid: str;
  has max_depth: int;
  has claimed: dict[str, bool] = {};
  has depth: int = 0;
  has collected: list[str] = [];

  can climb with Group entry {
    if here.gid in self.claimed {
      skip;
    }
    self.claimed[here.gid] = True;
    if here.gid != self.start_gid {
      self.collected.append(here.gid);
      print(here.gid);
    }
    if self.depth < self.max_depth {
      parents: list[Group] = [here <-:ChildGroups:<-][?:Group];
      if parents {
        self.depth += 1;
        visit :0: parents;
      }
    }
  }
}

node DemoAnchor {
  has store: dict[str, Group];
}

walker DemoW {
  can run with DemoAnchor entry {
    print(has_path_down(here.store, "org", "sub", 10));
    print(get_effective_groups(here.store, ["sub"], 10));
    disengage;
  }
}

def make_graph(parent_child_edges: list[list[str]]) -> dict[str, Group] {
  store: dict[str, Group] = {};
  for e in parent_child_edges {
    pg: str = e[0];
    cg: str = e[1];
    if pg not in store {
      pnd = Group(gid=pg);
      root ++> pnd;
      store[pg] = pnd;
    }
    if cg not in store {
      cnd = Group(gid=cg);
      root ++> cnd;
      store[cg] = cnd;
    }
    store[pg] +>:ChildGroups:+> store[cg];
  }
  return store;
}

def has_path_down(store: dict[str, Group], from_gid: str, to_gid: str, max_depth: int = 10) -> bool {
  if from_gid not in store or to_gid not in store {
    return False;
  }
  if from_gid == to_gid {
    return True;
  }
  w = store[from_gid] spawn PathDownW(target=to_gid, max_depth=max_depth);
  return w.found;
}

def get_effective_groups(store: dict[str, Group], member_gids: list[str], max_depth: int = 10) -> list[str] {
  result: dict[str, bool] = {};
  for mg in member_gids {
    if mg not in store {
      continue;
    }
    w = store[mg] spawn AncestorsW(start_gid=mg, max_depth=max_depth);
    for gid in w.collected {
      result[gid] = True;
    }
  }
  keys: list[str] = [];
  for k in result {
    keys.append(k);
  }
  return sorted(keys);
}

with entry {
  store: dict[str, Group] = make_graph([["org", "team"], ["team", "sub"]]);
  da = DemoAnchor(store=store);
  root ++> da;
  root spawn DemoW();
}
