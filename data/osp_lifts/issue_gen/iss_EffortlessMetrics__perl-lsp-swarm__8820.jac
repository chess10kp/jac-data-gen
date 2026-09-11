"""EffortlessMetrics/perl-lsp-swarm#8820 — reverse invalidation closure."""

node Module {
    has name: str;
}

edge DependsOn {}

obj CompilerWorld {
    has modules: dict[str, Module] = {};
}

walker ReverseInvalidate {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Module entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        visit [<-:DependsOn:<-][?:Module];
    }
}

def load_world(
    modules: list[str],
    depends: list[tuple[str, str]],
) -> CompilerWorld {
    world = CompilerWorld();
    for name in modules {
        nd = Module(name=name);
        root ++> nd;
        world.modules[name] = nd;
    }
    for (src, dst) in depends {
        s = world.modules.get(src, None);
        d = world.modules.get(dst, None);
        if s is not None and d is not None { s +>:DependsOn:+> d; }
    }
    return world;
}

def reverse_invalidation_closure(world: CompilerWorld, changed: str) -> list[str] {
    nd = world.modules.get(changed, None);
    if nd is None { return []; }
    w = nd spawn ReverseInvalidate(claimed={}, order=[]);
    return w.order;
}

def classify_transition(old_iface: set[str], new_iface: set[str]) -> str {
    if old_iface == new_iface { return "no_change"; }
    if old_iface.issubset(new_iface) or new_iface.issubset(old_iface) {
        return "public_change";
    }
    return "unknown";
}

def invalidate_for_transition(
    world: CompilerWorld,
    changed: str,
    transition: str,
) -> list[str] {
    if transition == "no_change" {
        return [changed] if changed in world.modules else [];
    }
    return reverse_invalidation_closure(world, changed);
}
