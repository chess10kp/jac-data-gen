"""Heliobond/backend#409: evaluate flag dependencies without recursive cycles."""

node Flag {
  has name: str;
  has enabled: bool = False;
  has rollout_percentage: int = 0;
  has depends_on: list[str] = [];
}

edge DependsOn {}

obj FlagDefinition {
  has enabled: bool = False;
  has rollout_percentage: int = 0;
  has depends_on: list[str] = [];
}

obj EvaluationResult {
  has value: bool;
  has reason: str;
}

obj FlagStore {
  has specs: dict[str, FlagDefinition] = {};
  has flags: dict[str, Flag] = {};
}

walker Reach {
  has target: str;
  has claimed: dict[str, bool] = {};
  has found: bool = False;

  can step with Flag entry {
    if here.cid in self.claimed {
      skip;
    }
    self.claimed[here.cid] = True;
    print("reach " + here.name);
    if here.name == self.target {
      self.found = True;
      skip;
    }
    for kid in [here ->:DependsOn:->][?:Flag] {
      visit :0: [kid];
    }
  }
}

walker Evaluate {
  has store: FlagStore;
  has claimed: dict[str, bool] = {};
  has cycle: bool = False;
  has blocked: bool = False;
  has missing: bool = False;

  can step with Flag entry {
    if here.cid in self.claimed {
      skip;
    }
    self.claimed[here.cid] = True;
    print("evaluate " + here.name);
    if not here.enabled {
      self.blocked = True;
    }
    if here.rollout_percentage <= 0 {
      self.blocked = True;
    }
    for dep_name in here.depends_on {
      if dep_name in self.store.flags {
      } else {
        self.missing = True;
      }
    }
    for kid in [here ->:DependsOn:->][?:Flag] {
      probe = kid spawn Reach(target=here.name, claimed={});
      if probe.found {
        self.cycle = True;
      }
      visit :0: [kid];
    }
  }
}

def _rebuild(store: FlagStore) -> None {
  fresh: dict[str, Flag] = {};
  for name in store.specs {
    spec = store.specs[name];
    fresh[name] = Flag(
      name=name,
      enabled=spec.enabled,
      rollout_percentage=spec.rollout_percentage,
      depends_on=spec.depends_on
    );
  }
  store.flags = fresh;
  for name in store.specs {
    source = store.flags[name];
    for dep_name in source.depends_on {
      if dep_name in store.flags {
        target = store.flags[dep_name];
        source +>:DependsOn:+> target;
      }
    }
  }
}

def load_flags(
  store: FlagStore,
  definitions: dict[str, FlagDefinition]
) -> None {
  store.specs = {};
  for name in definitions {
    store.specs[name] = definitions[name];
  }
  _rebuild(store);
}

def merge_flags(
  store: FlagStore,
  definitions: dict[str, FlagDefinition]
) -> None {
  for name in definitions {
    store.specs[name] = definitions[name];
  }
  _rebuild(store);
}

def evaluate_flag(store: FlagStore, name: str) -> EvaluationResult {
  if name in store.flags {
  } else {
    return EvaluationResult(value=False, reason="unknown_flag");
  }
  flag = store.flags[name];
  w = flag spawn Evaluate(store=store, claimed={});
  if w.missing {
    return EvaluationResult(value=False, reason="unknown_dependency");
  }
  if w.cycle {
    return EvaluationResult(value=False, reason="dependency_cycle");
  }
  if w.blocked {
    return EvaluationResult(value=False, reason="dependency_disabled");
  }
  return EvaluationResult(value=True, reason="enabled");
}

test "diamond revisit is not a cycle" {
  store = FlagStore();
  definitions: dict[str, FlagDefinition] = {};
  definitions["root"] = FlagDefinition(
    enabled=True,
    rollout_percentage=100,
    depends_on=["left", "right"]
  );
  definitions["left"] = FlagDefinition(
    enabled=True,
    rollout_percentage=100,
    depends_on=["shared"]
  );
  definitions["right"] = FlagDefinition(
    enabled=True,
    rollout_percentage=100,
    depends_on=["shared", "deep"]
  );
  definitions["shared"] = FlagDefinition(
    enabled=True,
    rollout_percentage=100,
    depends_on=[]
  );
  definitions["deep"] = FlagDefinition(
    enabled=True,
    rollout_percentage=100,
    depends_on=[]
  );
  load_flags(store, definitions);
  result = evaluate_flag(store, "root");
  assert (result.value);
  assert (result.reason == "enabled");
}

test "circular dependency returns dependency cycle" {
  store = FlagStore();
  definitions: dict[str, FlagDefinition] = {};
  definitions["a"] = FlagDefinition(
    enabled=True,
    rollout_percentage=100,
    depends_on=["b"]
  );
  definitions["b"] = FlagDefinition(
    enabled=True,
    rollout_percentage=100,
    depends_on=["a"]
  );
  load_flags(store, definitions);
  result = evaluate_flag(store, "a");
  assert (not result.value);
  assert (result.reason == "dependency_cycle");
}

test "unknown flag and dependency are tolerated" {
  store = FlagStore();
  definitions: dict[str, FlagDefinition] = {};
  definitions["safe"] = FlagDefinition(
    enabled=True,
    rollout_percentage=100,
    depends_on=["missing"]
  );
  load_flags(store, definitions);
  absent = evaluate_flag(store, "absent");
  broken = evaluate_flag(store, "safe");
  assert (absent.reason == "unknown_flag");
  assert (broken.reason == "unknown_dependency");
}

test "disabled and zero rollout flags are rejected" {
  store = FlagStore();
  definitions: dict[str, FlagDefinition] = {};
  definitions["disabled"] = FlagDefinition(
    enabled=False,
    rollout_percentage=100,
    depends_on=[]
  );
  definitions["zero"] = FlagDefinition(
    enabled=True,
    rollout_percentage=0,
    depends_on=[]
  );
  load_flags(store, definitions);
  disabled = evaluate_flag(store, "disabled");
  zero = evaluate_flag(store, "zero");
  assert (not disabled.value);
  assert (disabled.reason == "dependency_disabled");
  assert (not zero.value);
  assert (zero.reason == "dependency_disabled");
}

test "merge adds and evaluates a new flag" {
  store = FlagStore();
  initial: dict[str, FlagDefinition] = {};
  initial["base"] = FlagDefinition(
    enabled=True,
    rollout_percentage=100,
    depends_on=[]
  );
  load_flags(store, initial);
  patch: dict[str, FlagDefinition] = {};
  patch["new_flag"] = FlagDefinition(
    enabled=True,
    rollout_percentage=100,
    depends_on=["base"]
  );
  merge_flags(store, patch);
  result = evaluate_flag(store, "new_flag");
  assert (result.value);
  assert (result.reason == "enabled");
}
