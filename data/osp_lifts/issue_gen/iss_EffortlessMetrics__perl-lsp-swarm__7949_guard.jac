"""EffortlessMetrics/perl-lsp-swarm#7949 — compiler cache restart equivalence oracle."""

node Artifact {
    has name: str;
}

edge Depends {}

obj CompilerCacheWorld {
    has artifacts: dict[str, Artifact] = {};
    has keys: dict[str, str] = {};
    has digests: dict[str, str] = {};
}

walker DepClosureWalk {
    has claimed: dict[str, bool] = {};

    can step with Artifact entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        deps = [here ->:Depends:->][?:Artifact];
        names: list[str] = [];
        for d in deps { names.append(d.name); }
        for nm in sorted(names) {
            for d in deps {
                if d.name == nm { visit [d]; }
            }
        }
    }
}

walker InvalidationWalk {
    has claimed: dict[str, bool] = {};

    can step with Artifact entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        consumers = [here <-:Depends:<-][?:Artifact];
        names: list[str] = [];
        for c in consumers { names.append(c.name); }
        for nm in sorted(names) {
            for c in consumers {
                if c.name == nm { visit [c]; }
            }
        }
    }
}

def load_compiler_cache_world(
    artifacts: list[str],
    depends: list[tuple[str, str]],
    keys: dict[str, str],
    digests: dict[str, str],
) -> CompilerCacheWorld {
    w = CompilerCacheWorld();
    for art in artifacts {
        nd = Artifact(name=art);
        root ++> nd;
        w.artifacts[art] = nd;
    }
    for (consumer, dep) in depends {
        if consumer in w.artifacts and dep in w.artifacts {
            con = w.artifacts[consumer];
            de = w.artifacts[dep];
            existing = [con ->:Depends:->][?:Artifact];
            dup = False;
            for e in existing {
                if e.name == dep { dup = True; }
            }
            if not dup { con +>:Depends:+> de; }
        }
    }
    w.keys = dict(keys);
    w.digests = dict(digests);
    return w;
}

def dependency_closure(w: CompilerCacheWorld, artifact: str) -> list[str] {
    if artifact not in w.artifacts { return []; }
    nd = w.artifacts[artifact];
    depw = nd spawn DepClosureWalk(claimed={});
    out: list[str] = [];
    for k in depw.claimed { out.append(k); }
    return sorted(out);
}

def invalidation_closure(w: CompilerCacheWorld, seeds: list[str]) -> list[str] {
    claimed: dict[str, bool] = {};
    root_keys: list[str] = [];
    for s in seeds {
        if s in w.artifacts { root_keys.append(s); }
    }
    if len(root_keys) == 0 { return []; }
    for s in sorted(root_keys) {
        nd = w.artifacts[s];
        inv = nd spawn InvalidationWalk(claimed=claimed);
        claimed = inv.claimed;
    }
    out: list[str] = [];
    for k in claimed { out.append(k); }
    return sorted(out);
}

def checkpoint_status(
    w: CompilerCacheWorld,
    manifest_roots: list[str],
    current_keys: dict[str, str],
) -> dict[str, str] {
    needed: dict[str, bool] = {};
    for mroot in manifest_roots {
        for art in dependency_closure(w, mroot) {
            needed[art] = True;
        }
    }
    need_keys: list[str] = [];
    for k in needed { need_keys.append(k); }
    out: dict[str, str] = {};
    for art in sorted(need_keys) {
        if art not in w.artifacts {
            out[art] = "miss";
        } elif not w.digests.get(art, "") {
            out[art] = "quarantine";
        } elif current_keys.get(art, "") != w.keys.get(art, "") {
            out[art] = "recompute";
        } else {
            out[art] = "adopt";
        }
    }
    return out;
}

def corruption_fallback(*, decode_ok: bool, digest_ok: bool, schema_ok: bool) -> str {
    if not schema_ok { return "cold"; }
    if not decode_ok or not digest_ok { return "quarantine"; }
    return "adopt";
}

def provider_is_current(
    w: CompilerCacheWorld,
    provider_art: str,
    invalidated: list[str],
) -> bool {
    if provider_art not in w.artifacts { return False; }
    bad: dict[str, bool] = {};
    for x in invalidated { bad[x] = True; }
    if provider_art in bad { return False; }
    nd = w.artifacts[provider_art];
    deps = [nd ->:Depends:->][?:Artifact];
    for dep in deps {
        if dep.name in bad { return False; }
    }
    return True;
}

def bust_live_cache(
    w: CompilerCacheWorld,
    seeds: list[str],
    cache: dict[str, str],
) -> list[str] {
    victims = invalidation_closure(w, seeds);
    for art in victims {
        if art in cache {
            del cache[art];
        }
    }
    return victims;
}

test "diamond revisit dependency closure includes origin" {
    w = load_compiler_cache_world(
        ["root", "left", "right", "join"],
        [("root", "left"), ("root", "right"), ("left", "join"), ("right", "join")],
        {},
        {},
    );
    assert dependency_closure(w, "root") == ["join", "left", "right", "root"];;
    assert dependency_closure(w, "join") == ["join"];;
}

test "diamond invalidation fanout and merged seed walks" {
    w = load_compiler_cache_world(
        ["hub", "leaf", "mid_a", "mid_b"],
        [("leaf", "hub"), ("mid_a", "leaf"), ("mid_b", "leaf")],
        {},
        {},
    );
    assert invalidation_closure(w, ["hub"]) == ["hub", "leaf", "mid_a", "mid_b"];;
    assert invalidation_closure(w, ["mid_a"]) == ["mid_a"];;
    assert invalidation_closure(w, ["leaf", "mid_b"]) == ["leaf", "mid_a", "mid_b"];;
}

test "unknown id tolerance and ignored foreign edges" {
    w = load_compiler_cache_world(
        ["only"],
        [("only", "ghost"), ("phantom", "only"), ("only", "only")],
        {},
        {},
    );
    assert dependency_closure(w, "missing") == [];;
    assert invalidation_closure(w, []) == [];;
    assert invalidation_closure(w, ["missing", "ghost"]) == [];;
    assert checkpoint_status(w, ["ghost", "missing"], {}) == {};;
    assert provider_is_current(w, "ghost", []) is False;;
    assert provider_is_current(w, "only", ["only"]) is False;;
    assert dependency_closure(w, "only") == ["only"];;
}

test "cyclic depends and reverse invalidation terminate" {
    w = load_compiler_cache_world(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
        {},
        {},
    );
    assert dependency_closure(w, "a") == ["a", "b", "c"];;
    assert invalidation_closure(w, ["a"]) == ["a", "b", "c"];;
}

test "checkpoint status adopt recompute quarantine matrix" {
    w = load_compiler_cache_world(
        ["root", "stale", "dirty", "bare"],
        [("root", "stale"), ("root", "dirty"), ("root", "bare")],
        {"root": "k0", "stale": "k1", "dirty": "k2", "bare": "k3"},
        {"root": "d0", "stale": "d1", "dirty": "d2", "bare": ""},
    );
    st = checkpoint_status(
        w,
        ["root"],
        {"root": "k0", "stale": "k1", "dirty": "wrong", "bare": "k3"},
    );
    assert st == {"bare": "quarantine", "dirty": "recompute", "root": "adopt", "stale": "adopt"};;
}

test "provider gate bust cache and corruption fallback" {
    w = load_compiler_cache_world(
        ["prov", "dep", "sink"],
        [("prov", "dep"), ("sink", "prov")],
        {},
        {},
    );
    assert provider_is_current(w, "prov", ["dep"]) is False;;
    assert provider_is_current(w, "prov", ["sink"]) is True;;
    cache = {"prov": "v", "dep": "v", "sink": "v", "other": "v"};
    victims = bust_live_cache(w, ["dep"], cache);
    assert sorted(victims) == ["dep", "prov", "sink"];;
    assert "other" in cache;;
    assert corruption_fallback(decode_ok=False, digest_ok=True, schema_ok=True) == "quarantine";;
    assert corruption_fallback(decode_ok=True, digest_ok=True, schema_ok=False) == "cold";;
}
