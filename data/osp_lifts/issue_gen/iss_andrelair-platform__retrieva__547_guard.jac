"""andrelair-platform/retrieva#547 — recursive-CTE traversal repository (cycle-safe)."""

node Provider {
    has pid: str;
}

node Function {
    has fid: str;
}

node Arrangement {
    has aid: str;
}

edge Subcontract {}
edge Reaches {}
edge Delegates {}

walker SubChainWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";
    has max_depth: int = 50;
    has depth: int = 0;

    can sub_step with Provider entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        self.depth += 1;
        print("sub_visit", here.pid);
        if self.depth > self.max_depth {
            disengage;
        }
        if here.pid != self.origin {
            self.found.append(here.pid);
        }
        kids: list[Provider] = [here ->:Subcontract:->][?:Provider];
        for kid in kids {
            visit :0: [kid];
        }
    }
}

walker ArrReachWalker {
    has claimed_fn: dict[str, bool] = {};
    has claimed_arr: dict[str, bool] = {};
    has found: list[str] = [];
    has max_depth: int = 50;
    has depth: int = 0;

    can fn_step with Function entry {
        if here.fid in self.claimed_fn {
            skip;
        }
        self.claimed_fn[here.fid] = True;
        print("fn_visit", here.fid);
        arrs: list[Arrangement] = [here <-:Reaches:<-][?:Arrangement];
        for a in arrs {
            visit :0: [a];
        }
    }

    can arr_step with Arrangement entry {
        if here.aid in self.claimed_arr {
            skip;
        }
        self.claimed_arr[here.aid] = True;
        self.depth += 1;
        print("arr_visit", here.aid);
        if self.depth > self.max_depth {
            disengage;
        }
        self.found.append(here.aid);
        ups: list[Arrangement] = [here <-:Delegates:<-][?:Arrangement];
        for u in ups {
            visit :0: [u];
        }
    }
}

obj RecursiveCteRepo {
    has provider_by_id: dict[str, Provider] = {};
    has function_by_id: dict[str, Function] = {};
    has arrangement_by_id: dict[str, Arrangement] = {};
}

def add_provider(repo: RecursiveCteRepo, pid: str) -> Provider {
    nd = Provider(pid=pid);
    root ++> nd;
    repo.provider_by_id[pid] = nd;
    return nd;
}

def add_function(repo: RecursiveCteRepo, fid: str) -> Function {
    nd = Function(fid=fid);
    root ++> nd;
    repo.function_by_id[fid] = nd;
    return nd;
}

def add_arrangement(repo: RecursiveCteRepo, aid: str) -> Arrangement {
    nd = Arrangement(aid=aid);
    root ++> nd;
    repo.arrangement_by_id[aid] = nd;
    return nd;
}

def link_provider_sub(repo: RecursiveCteRepo, parent_id: str, child_id: str) -> None {
    p: Provider = repo.provider_by_id[parent_id];
    c: Provider = repo.provider_by_id[child_id];
    p +>:Subcontract:+> c;
}

def link_arr_reaches_fn(repo: RecursiveCteRepo, aid: str, fid: str) -> None {
    a: Arrangement = repo.arrangement_by_id[aid];
    f: Function = repo.function_by_id[fid];
    a +>:Reaches:+> f;
}

def link_arr_delegates(repo: RecursiveCteRepo, parent_id: str, child_id: str) -> None {
    p: Arrangement = repo.arrangement_by_id[parent_id];
    c: Arrangement = repo.arrangement_by_id[child_id];
    p +>:Delegates:+> c;
}

def provider_subcontractor_chain(repo: RecursiveCteRepo, provider_id: str) -> list[str] {
    if provider_id not in repo.provider_by_id {
        empty: list[str] = [];
        return empty;
    }
    start: Provider = repo.provider_by_id[provider_id];
    w = start spawn SubChainWalker(
        claimed={},
        found=[],
        origin=provider_id,
        max_depth=50,
        depth=0
    );
    out: list[str] = w.found;
    return sorted(out);
}

def arrangements_reaching_function(repo: RecursiveCteRepo, function_id: str) -> list[str] {
    if function_id not in repo.function_by_id {
        empty: list[str] = [];
        return empty;
    }
    start_fn: Function = repo.function_by_id[function_id];
    wk = start_fn spawn ArrReachWalker(
        claimed_fn={},
        claimed_arr={},
        found=[],
        max_depth=50,
        depth=0
    );
    out: list[str] = wk.found;
    return sorted(out);
}

"""andrelair-platform/retrieva#547 — recursive-CTE traversal repository (cycle-safe)."""

node Provider {
    has pid: str;
}

node Function {
    has fid: str;
}

node Arrangement {
    has aid: str;
}

edge Subcontract {}
edge Reaches {}
edge Delegates {}

walker SubChainWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";
    has max_depth: int = 50;
    has depth: int = 0;

    can sub_step with Provider entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        self.depth += 1;
        print("sub_visit", here.pid);
        if self.depth > self.max_depth {
            disengage;
        }
        if here.pid != self.origin {
            self.found.append(here.pid);
        }
        kids: list[Provider] = [here ->:Subcontract:->][?:Provider];
        for kid in kids {
            visit :0: [kid];
        }
    }
}

walker ArrReachWalker {
    has claimed_fn: dict[str, bool] = {};
    has claimed_arr: dict[str, bool] = {};
    has found: list[str] = [];
    has max_depth: int = 50;
    has depth: int = 0;

    can fn_step with Function entry {
        if here.fid in self.claimed_fn {
            skip;
        }
        self.claimed_fn[here.fid] = True;
        print("fn_visit", here.fid);
        arrs: list[Arrangement] = [here <-:Reaches:<-][?:Arrangement];
        for a in arrs {
            visit :0: [a];
        }
    }

    can arr_step with Arrangement entry {
        if here.aid in self.claimed_arr {
            skip;
        }
        self.claimed_arr[here.aid] = True;
        self.depth += 1;
        print("arr_visit", here.aid);
        if self.depth > self.max_depth {
            disengage;
        }
        self.found.append(here.aid);
        ups: list[Arrangement] = [here <-:Delegates:<-][?:Arrangement];
        for u in ups {
            visit :0: [u];
        }
    }
}

obj RecursiveCteRepo {
    has provider_by_id: dict[str, Provider] = {};
    has function_by_id: dict[str, Function] = {};
    has arrangement_by_id: dict[str, Arrangement] = {};
}

def add_provider(repo: RecursiveCteRepo, pid: str) -> Provider {
    nd = Provider(pid=pid);
    root ++> nd;
    repo.provider_by_id[pid] = nd;
    return nd;
}

def add_function(repo: RecursiveCteRepo, fid: str) -> Function {
    nd = Function(fid=fid);
    root ++> nd;
    repo.function_by_id[fid] = nd;
    return nd;
}

def add_arrangement(repo: RecursiveCteRepo, aid: str) -> Arrangement {
    nd = Arrangement(aid=aid);
    root ++> nd;
    repo.arrangement_by_id[aid] = nd;
    return nd;
}

def link_provider_sub(repo: RecursiveCteRepo, parent_id: str, child_id: str) -> None {
    p: Provider = repo.provider_by_id[parent_id];
    c: Provider = repo.provider_by_id[child_id];
    p +>:Subcontract:+> c;
}

def link_arr_reaches_fn(repo: RecursiveCteRepo, aid: str, fid: str) -> None {
    a: Arrangement = repo.arrangement_by_id[aid];
    f: Function = repo.function_by_id[fid];
    a +>:Reaches:+> f;
}

def link_arr_delegates(repo: RecursiveCteRepo, parent_id: str, child_id: str) -> None {
    p: Arrangement = repo.arrangement_by_id[parent_id];
    c: Arrangement = repo.arrangement_by_id[child_id];
    p +>:Delegates:+> c;
}

def provider_subcontractor_chain(repo: RecursiveCteRepo, provider_id: str) -> list[str] {
    if provider_id not in repo.provider_by_id {
        empty: list[str] = [];
        return empty;
    }
    start: Provider = repo.provider_by_id[provider_id];
    w = start spawn SubChainWalker(
        claimed={},
        found=[],
        origin=provider_id,
        max_depth=50,
        depth=0
    );
    out: list[str] = w.found;
    return sorted(out);
}

def arrangements_reaching_function(repo: RecursiveCteRepo, function_id: str) -> list[str] {
    if function_id not in repo.function_by_id {
        empty: list[str] = [];
        return empty;
    }
    start_fn: Function = repo.function_by_id[function_id];
    wk = start_fn spawn ArrReachWalker(
        claimed_fn={},
        claimed_arr={},
        found=[],
        max_depth=50,
        depth=0
    );
    out: list[str] = wk.found;
    return sorted(out);
}

test "sub_chain_diamond_revisit_once" {
    repo = RecursiveCteRepo();
    add_provider(repo, "top");
    add_provider(repo, "l");
    add_provider(repo, "r");
    add_provider(repo, "bot");
    link_provider_sub(repo, "top", "l");
    link_provider_sub(repo, "top", "r");
    link_provider_sub(repo, "l", "bot");
    link_provider_sub(repo, "r", "bot");
    got = provider_subcontractor_chain(repo, "top");
    assert got == ["bot", "l", "r"];
}

test "sub_chain_unknown_provider" {
    repo = RecursiveCteRepo();
    got = provider_subcontractor_chain(repo, "missing");
    assert got == [];
}

test "sub_chain_linear" {
    repo = RecursiveCteRepo();
    add_provider(repo, "a");
    add_provider(repo, "b");
    add_provider(repo, "c");
    link_provider_sub(repo, "a", "b");
    link_provider_sub(repo, "b", "c");
    got = provider_subcontractor_chain(repo, "a");
    assert got == ["b", "c"];
}

test "sub_chain_cycle_skip" {
    repo = RecursiveCteRepo();
    add_provider(repo, "a");
    add_provider(repo, "b");
    add_provider(repo, "c");
    link_provider_sub(repo, "a", "b");
    link_provider_sub(repo, "b", "c");
    link_provider_sub(repo, "c", "a");
    got = provider_subcontractor_chain(repo, "a");
    assert got == ["b", "c"];
}

test "arr_reach_delegate_closure" {
    repo = RecursiveCteRepo();
    add_function(repo, "fn1");
    add_arrangement(repo, "arr1");
    add_arrangement(repo, "arr2");
    add_arrangement(repo, "arr3");
    link_arr_reaches_fn(repo, "arr1", "fn1");
    link_arr_reaches_fn(repo, "arr2", "fn1");
    link_arr_delegates(repo, "arr3", "arr2");
    got = arrangements_reaching_function(repo, "fn1");
    assert got == ["arr1", "arr2", "arr3"];
}

test "arr_reach_unknown_function" {
    repo = RecursiveCteRepo();
    got = arrangements_reaching_function(repo, "missing");
    assert got == [];
}
