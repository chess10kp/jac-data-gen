"""opena2a-org/hackmyagent#379 — parse-offset grant line citation (structure over text)."""

node ConfigKey {
  has cid: str;
  has key_name: str;
  has full_path: str;
  has line: int;
  has polarity: str;
  has grant_value: str;
  has depth: int = 0;
}

edge Nest {}

walker LineWalker {
  has target_path: str;
  has depth_limit: int = -1;
  has found_line: int = -1;
  has claimed: dict[str, bool] = {};

  can step with ConfigKey entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    if self.depth_limit >= 0 and here.depth > self.depth_limit {
      print("bounded ", here.full_path);
    } else {
      if here.full_path == self.target_path and here.grant_value != "" {
        self.found_line = here.line;
        print("line_hit ", here.full_path, " ", here.line);
      }
    }
    kids: list[ConfigKey] = [here ->:Nest:->][?:ConfigKey];
    for ch in kids {
      visit :0: [ch];
    }
  }
}

walker ValueWalker {
  has value: str;
  has polarity: str;
  has found_line: int = -1;
  has claimed: dict[str, bool] = {};

  can probe with ConfigKey entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    if here.grant_value == self.value and here.polarity == self.polarity {
      self.found_line = here.line;
      print("value_hit ", here.polarity, " ", here.line);
    }
    kids: list[ConfigKey] = [here ->:Nest:->][?:ConfigKey];
    for ch in kids {
      visit :0: [ch];
    }
  }
}

walker CollectWalker {
  has max_depth: int;
  has paths: list[str] = [];
  has claimed: dict[str, bool] = {};

  can gather with ConfigKey entry {
    if here.cid in self.claimed { skip; }
    if here.depth > self.max_depth {
      print("depth_skip ", here.full_path);
      skip;
    }
    self.claimed[here.cid] = True;
    if here.polarity == "allow" and here.grant_value != "" {
      self.paths.append(here.full_path);
      print("allow ", here.full_path, " ", here.line);
    }
    kids: list[ConfigKey] = [here ->:Nest:->][?:ConfigKey];
    for ch in kids {
      visit :0: [ch];
    }
  }
}

def connect_child(parent: ConfigKey, child: ConfigKey) -> None {
  parent +>:Nest:+> child;
}

def build_issue_tree() -> ConfigKey {
  graph_root = ConfigKey(
    cid="n0", key_name="root", full_path="", line=0,
    polarity="none", grant_value="", depth=0
  );
  perms = ConfigKey(
    cid="n1", key_name="permissions", full_path="permissions", line=2,
    polarity="none", grant_value="", depth=1
  );
  allow0 = ConfigKey(
    cid="n2", key_name="allow[0]", full_path="permissions.allow[0]", line=3,
    polarity="allow", grant_value="Read(src/**)", depth=2
  );
  deny0 = ConfigKey(
    cid="n3", key_name="deny[0]", full_path="permissions.deny[0]", line=4,
    polarity="deny", grant_value="Read(**/*.key)", depth=2
  );
  extra = ConfigKey(
    cid="n5", key_name="extra", full_path="permissions.extra", line=5,
    polarity="none", grant_value="", depth=2
  );
  extra_allow = ConfigKey(
    cid="n4", key_name="allow[0]", full_path="permissions.extra.allow[0]", line=5,
    polarity="allow", grant_value="Read(**/*.key)", depth=3
  );
  root ++> graph_root;
  connect_child(graph_root, perms);
  connect_child(perms, allow0);
  connect_child(perms, deny0);
  connect_child(perms, extra);
  connect_child(extra, extra_allow);
  return graph_root;
}

def build_diamond_tree() -> ConfigKey {
  graph_root = ConfigKey(
    cid="r0", key_name="root", full_path="", line=0,
    polarity="none", grant_value="", depth=0
  );
  apex = ConfigKey(
    cid="r1", key_name="permissions", full_path="permissions", line=1,
    polarity="none", grant_value="", depth=1
  );
  left = ConfigKey(
    cid="r2", key_name="left", full_path="permissions.left", line=2,
    polarity="none", grant_value="", depth=2
  );
  right = ConfigKey(
    cid="r3", key_name="right", full_path="permissions.right", line=3,
    polarity="none", grant_value="", depth=2
  );
  shared = ConfigKey(
    cid="alias_shared", key_name="grant", full_path="permissions.shared.grant", line=7,
    polarity="allow", grant_value="Read(**/*.key)", depth=3
  );
  root ++> graph_root;
  connect_child(graph_root, apex);
  connect_child(apex, left);
  connect_child(apex, right);
  connect_child(left, shared);
  connect_child(right, shared);
  return graph_root;
}

def grant_line_at(
  graph_root: ConfigKey, path: str, depth_limit: int = -1
) -> int | None {
  w = graph_root spawn LineWalker(
    target_path=path, depth_limit=depth_limit, claimed={}
  );
  if w.found_line < 0 {
    return None;
  }
  return w.found_line;
}

def structure_locate(
  graph_root: ConfigKey, value: str, polarity: str
) -> int | None {
  w = graph_root spawn ValueWalker(value=value, polarity=polarity, claimed={});
  if w.found_line < 0 {
    return None;
  }
  return w.found_line;
}

def collect_allow_lines(graph_root: ConfigKey, max_depth: int) -> list[str] {
  w = graph_root spawn CollectWalker(max_depth=max_depth, claimed={});
  out: list[str] = [];
  for p in w.paths {
    out.append(p);
  }
  return sorted(out);
}
