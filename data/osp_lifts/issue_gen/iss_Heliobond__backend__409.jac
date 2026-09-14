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
