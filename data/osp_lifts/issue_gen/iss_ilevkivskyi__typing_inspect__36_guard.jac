"""ilevkivskyi/typing_inspect#36 — normalize typing origins for recursive type-tree folds."""

node TypeStore { has label: str = "store"; }
node TypeExpr { has tid: str; has origin_raw: str; }
edge StoreLink {}
edge ChildArg {}

def normalize_origin(raw: str) -> str {
  aliases: dict[str, str] = {};
  aliases["collections.abc.Iterable"] = "typing.Iterable";
  aliases["collections.abc.Callable"] = "typing.Callable";
  aliases["collections.abc.Mapping"] = "typing.Mapping";
  aliases["collections.abc.Sequence"] = "typing.Sequence";
  if raw in aliases {
    return aliases[raw];
  }
  return raw;
}

def wire_store(store: TypeStore, expr: TypeExpr) -> TypeExpr {
  store +>:StoreLink:+> expr;
  return expr;
}

def link_child(parent: TypeExpr, child: TypeExpr) -> TypeExpr {
  parent +>:ChildArg:+> child;
  return child;
}

walker OriginLookup {
  has target_tid: str;
  has result: str = "";
  has claimed: dict[str, bool] = {};

  can seek_store with TypeStore entry {
    print("lookup", self.target_tid);
    exprs: list[TypeExpr] = [];
    for ln in [here ->:StoreLink:->][?:TypeExpr] {
      exprs.append(ln);
    }
    if exprs {
      visit exprs;
    } else {
      disengage;
    }
  }

  can seek_expr with TypeExpr entry {
    if here.tid in self.claimed { skip; }
    self.claimed[here.tid] = True;
    if here.tid == self.target_tid {
      self.result = normalize_origin(here.origin_raw);
      print("hit", self.target_tid, self.result);
      disengage;
    }
    chs: list[TypeExpr] = [];
    for ch in [here ->:ChildArg:->][?:TypeExpr] {
      chs.append(ch);
    }
    if chs {
      visit chs;
    }
  }
}

walker ArgsLookup {
  has target_tid: str;
  has result: list[str] = [];
  has claimed: dict[str, bool] = {};

  can seek_store with TypeStore entry {
    print("args_lookup", self.target_tid);
    exprs: list[TypeExpr] = [];
    for ln in [here ->:StoreLink:->][?:TypeExpr] {
      exprs.append(ln);
    }
    if exprs {
      visit exprs;
    } else {
      disengage;
    }
  }

  can seek_expr with TypeExpr entry {
    if here.tid in self.claimed { skip; }
    self.claimed[here.tid] = True;
    if here.tid == self.target_tid {
      args: list[str] = [];
      for ch in [here ->:ChildArg:->][?:TypeExpr] {
        args.append(ch.tid);
      }
      self.result = args;
      print("args_hit", self.target_tid, len(args));
      disengage;
    }
    chs: list[TypeExpr] = [];
    for ch in [here ->:ChildArg:->][?:TypeExpr] {
      chs.append(ch);
    }
    if chs {
      visit chs;
    }
  }
}

walker OriginCollector {
  has root_id: str;
  has claimed: dict[str, bool] = {};
  has found: list[str] = [];

  can start_store with TypeStore entry {
    print("collect", self.root_id);
    seeds: list[TypeExpr] = [];
    for ln in [here ->:StoreLink:->][?:TypeExpr] {
      if ln.tid == self.root_id {
        seeds.append(ln);
      }
    }
    if seeds {
      visit :0: seeds;
    } else {
      disengage;
    }
  }

  can walk_expr with TypeExpr entry {
    if here.tid in self.claimed { skip; }
    self.claimed[here.tid] = True;
    norm = normalize_origin(here.origin_raw);
    self.found.append(norm);
    print("walk", here.tid, norm);
    kids: list[TypeExpr] = [];
    for ch in [here ->:ChildArg:->][?:TypeExpr] {
      kids.append(ch);
    }
    if kids {
      i: int = len(kids) - 1;
      while i >= 0 {
        visit :0: [kids[i]];
        i -= 1;
      }
    }
  }
}

def get_origin(store: TypeStore, type_id: str) -> str {
  w = store spawn OriginLookup(target_tid=type_id);
  return w.result;
}

def get_args(store: TypeStore, type_id: str) -> list[str] {
  w = store spawn ArgsLookup(target_tid=type_id);
  return w.result;
}

def collect_origins(store: TypeStore, root_id: str) -> list[str] {
  w = store spawn OriginCollector(root_id=root_id);
  out: list[str] = sorted(w.found);
  return out;
}

with entry {
  st = TypeStore(label="demo");
  root ++> st;
  iterable = TypeExpr(tid="iter", origin_raw="collections.abc.Iterable");
  arg_int = TypeExpr(tid="int_t", origin_raw="builtins.int");
  wire_store(st, iterable);
  link_child(iterable, arg_int);
  w = root spawn OriginCollector(root_id="iter");
  print("demo_origin", get_origin(st, "iter"));
  print("demo_args", get_args(st, "iter"));
  print("demo_collect", sorted(w.found));
}

"""ilevkivskyi/typing_inspect#36 — normalize typing origins for recursive type-tree folds."""

node TypeStore { has label: str = "store"; }
node TypeExpr { has tid: str; has origin_raw: str; }
edge StoreLink {}
edge ChildArg {}

def normalize_origin(raw: str) -> str {
  aliases: dict[str, str] = {};
  aliases["collections.abc.Iterable"] = "typing.Iterable";
  aliases["collections.abc.Callable"] = "typing.Callable";
  aliases["collections.abc.Mapping"] = "typing.Mapping";
  aliases["collections.abc.Sequence"] = "typing.Sequence";
  if raw in aliases {
    return aliases[raw];
  }
  return raw;
}

def wire_store(store: TypeStore, expr: TypeExpr) -> TypeExpr {
  store +>:StoreLink:+> expr;
  return expr;
}

def link_child(parent: TypeExpr, child: TypeExpr) -> TypeExpr {
  parent +>:ChildArg:+> child;
  return child;
}

walker OriginLookup {
  has target_tid: str;
  has result: str = "";
  has claimed: dict[str, bool] = {};

  can seek_store with TypeStore entry {
    print("lookup", self.target_tid);
    exprs: list[TypeExpr] = [];
    for ln in [here ->:StoreLink:->][?:TypeExpr] {
      exprs.append(ln);
    }
    if exprs {
      visit exprs;
    } else {
      disengage;
    }
  }

  can seek_expr with TypeExpr entry {
    if here.tid in self.claimed { skip; }
    self.claimed[here.tid] = True;
    if here.tid == self.target_tid {
      self.result = normalize_origin(here.origin_raw);
      print("hit", self.target_tid, self.result);
      disengage;
    }
    chs: list[TypeExpr] = [];
    for ch in [here ->:ChildArg:->][?:TypeExpr] {
      chs.append(ch);
    }
    if chs {
      visit chs;
    }
  }
}

walker ArgsLookup {
  has target_tid: str;
  has result: list[str] = [];
  has claimed: dict[str, bool] = {};

  can seek_store with TypeStore entry {
    print("args_lookup", self.target_tid);
    exprs: list[TypeExpr] = [];
    for ln in [here ->:StoreLink:->][?:TypeExpr] {
      exprs.append(ln);
    }
    if exprs {
      visit exprs;
    } else {
      disengage;
    }
  }

  can seek_expr with TypeExpr entry {
    if here.tid in self.claimed { skip; }
    self.claimed[here.tid] = True;
    if here.tid == self.target_tid {
      args: list[str] = [];
      for ch in [here ->:ChildArg:->][?:TypeExpr] {
        args.append(ch.tid);
      }
      self.result = args;
      print("args_hit", self.target_tid, len(args));
      disengage;
    }
    chs: list[TypeExpr] = [];
    for ch in [here ->:ChildArg:->][?:TypeExpr] {
      chs.append(ch);
    }
    if chs {
      visit chs;
    }
  }
}

walker OriginCollector {
  has root_id: str;
  has claimed: dict[str, bool] = {};
  has found: list[str] = [];

  can start_store with TypeStore entry {
    print("collect", self.root_id);
    seeds: list[TypeExpr] = [];
    for ln in [here ->:StoreLink:->][?:TypeExpr] {
      if ln.tid == self.root_id {
        seeds.append(ln);
      }
    }
    if seeds {
      visit :0: seeds;
    } else {
      disengage;
    }
  }

  can walk_expr with TypeExpr entry {
    if here.tid in self.claimed { skip; }
    self.claimed[here.tid] = True;
    norm = normalize_origin(here.origin_raw);
    self.found.append(norm);
    print("walk", here.tid, norm);
    kids: list[TypeExpr] = [];
    for ch in [here ->:ChildArg:->][?:TypeExpr] {
      kids.append(ch);
    }
    if kids {
      i: int = len(kids) - 1;
      while i >= 0 {
        visit :0: [kids[i]];
        i -= 1;
      }
    }
  }
}

def get_origin(store: TypeStore, type_id: str) -> str {
  w = store spawn OriginLookup(target_tid=type_id);
  return w.result;
}

def get_args(store: TypeStore, type_id: str) -> list[str] {
  w = store spawn ArgsLookup(target_tid=type_id);
  return w.result;
}

def collect_origins(store: TypeStore, root_id: str) -> list[str] {
  w = store spawn OriginCollector(root_id=root_id);
  out: list[str] = sorted(w.found);
  return out;
}

test "normalize_alias" {
  assert normalize_origin("collections.abc.Iterable") == "typing.Iterable";
  assert normalize_origin("typing.Union") == "typing.Union";
}

test "get_origin_hit" {
  st = TypeStore(label="t");
  root ++> st;
  expr = TypeExpr(tid="iter", origin_raw="collections.abc.Iterable");
  wire_store(st, expr);
  got = get_origin(st, "iter");
  assert got == "typing.Iterable";
}

test "get_args_children" {
  st = TypeStore(label="t");
  root ++> st;
  parent = TypeExpr(tid="iter", origin_raw="collections.abc.Iterable");
  child = TypeExpr(tid="int_t", origin_raw="builtins.int");
  wire_store(st, parent);
  link_child(parent, child);
  got = get_args(st, "iter");
  expect: list[str] = ["int_t"];
  assert got == expect;
}

test "collect_linear" {
  st = TypeStore(label="t");
  root ++> st;
  parent = TypeExpr(tid="iter", origin_raw="collections.abc.Iterable");
  child = TypeExpr(tid="int_t", origin_raw="builtins.int");
  wire_store(st, parent);
  link_child(parent, child);
  got = collect_origins(st, "iter");
  expect: list[str] = ["builtins.int", "typing.Iterable"];
  assert got == expect;
}

test "diamond_shared_child_once" {
  st = TypeStore(label="t");
  root ++> st;
  union = TypeExpr(tid="union", origin_raw="typing.Union");
  left = TypeExpr(tid="left", origin_raw="collections.abc.Iterable");
  right = TypeExpr(tid="right", origin_raw="collections.abc.Iterable");
  shared_int = TypeExpr(tid="shared_int", origin_raw="builtins.int");
  wire_store(st, union);
  link_child(union, left);
  link_child(union, right);
  link_child(left, shared_int);
  link_child(right, shared_int);
  got = collect_origins(st, "union");
  expect: list[str] = [
    "builtins.int",
    "typing.Iterable",
    "typing.Iterable",
    "typing.Union",
  ];
  assert got == expect;
}

test "diamond_adversarial_revisit_skip" {
  st = TypeStore(label="t");
  root ++> st;
  apex = TypeExpr(tid="apex", origin_raw="collections.abc.Callable");
  a = TypeExpr(tid="a", origin_raw="collections.abc.Iterable");
  b = TypeExpr(tid="b", origin_raw="collections.abc.Iterable");
  leaf = TypeExpr(tid="leaf", origin_raw="builtins.int");
  wire_store(st, apex);
  link_child(apex, b);
  link_child(b, leaf);
  link_child(apex, a);
  link_child(a, leaf);
  got = collect_origins(st, "apex");
  expect: list[str] = [
    "builtins.int",
    "typing.Callable",
    "typing.Iterable",
    "typing.Iterable",
  ];
  assert len(got) == 4;
  assert got == expect;
}
