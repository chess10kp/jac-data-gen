node Func {
    has name: str;
    has arity: int = 0;
    has is_jit: bool = False;
    has array_param_mask: int = 0;
    has result_is_bool: bool = False;
}
node CallSite {
    has argc: int = 0;
}
node Vm {}
edge Anchors {}
edge CallsDirect {}
edge Targets {}

walker Collect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step_func with Func entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        print(here.name);
        for cs in [here ->:CallsDirect:->][?:CallSite] {
            visit :0: [cs];
        }
    }
    can step_call with CallSite entry {
        print("call-site");
        for tgt in [here ->:Targets:->][?:Func] {
            visit :0: [tgt];
        }
    }
}

walker JitCheck {
    has claimed: dict[str, bool] = {};
    has ok: bool = True;
    can check_func with Func entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print(here.name);
        for cs in [here ->:CallsDirect:->][?:CallSite] {
            for tgt in [cs ->:Targets:->][?:Func] {
                if tgt.is_jit == False { self.ok = False; }
                if tgt.array_param_mask != 0 { self.ok = False; }
                if tgt.result_is_bool == True { self.ok = False; }
                if tgt.arity != cs.argc { self.ok = False; }
            }
            visit :0: [cs];
        }
        for cs in [here ->:CallsDirect:->][?:CallSite] {
            for tgt in [cs ->:Targets:->][?:Func] {
                visit :0: [tgt];
            }
        }
    }
    can check_call with CallSite entry {
        print("jit-call-site");
        for tgt in [here ->:Targets:->][?:Func] {
            visit :0: [tgt];
        }
    }
}

def find_func(vm: Vm, name: str) -> Func | None {
    for f in [vm ->:Anchors:->][?:Func] {
        if f.name == name { return f; }
    }
    return None;
}

def make_vm() -> Vm {
    vm = Vm();
    return vm;
}
def new_vm() -> Vm { return make_vm(); }

def add_func(vm: Vm, name: str, arity: int, is_jit: bool) -> Func {
    f = Func(name=name, arity=arity, is_jit=is_jit, array_param_mask=0, result_is_bool=False);
    vm +>:Anchors:+> f;
    return f;
}
def add_func_ex(vm: Vm, name: str, arity: int, is_jit: bool, array_param_mask: int, result_is_bool: bool) -> Func {
    f = Func(name=name, arity=arity, is_jit=is_jit, array_param_mask=array_param_mask, result_is_bool=result_is_bool);
    vm +>:Anchors:+> f;
    return f;
}
def vm_add_func(vm: Vm, name: str, arity: int, is_jit: bool) -> Func { return add_func(vm, name, arity, is_jit); }

def add_call(vm: Vm, caller: str, callee: str, argc: int) -> bool {
    c = find_func(vm, caller);
    if c is None { return False; }
    t = find_func(vm, callee);
    if t is None { return False; }
    cs = CallSite(argc=argc);
    c +>:CallsDirect:+> cs;
    cs +>:Targets:+> t;
    return True;
}
def add_direct_call(vm: Vm, caller: str, callee: str, argc: int) -> bool { return add_call(vm, caller, callee, argc); }
def vm_add_direct_call(vm: Vm, caller: str, callee: str, argc: int) -> bool { return add_call(vm, caller, callee, argc); }

def reachable(vm: Vm, start: str) -> list[str] {
    f = find_func(vm, start);
    if f is None { return []; }
    w = f spawn Collect();
    return w.found;
}
def reachable_from(vm: Vm, start: str) -> list[str] { return reachable(vm, start); }
def get_reachable(vm: Vm, start: str) -> list[str] { return reachable(vm, start); }
def vm_reachable(vm: Vm, start: str) -> list[str] { return reachable(vm, start); }

def can_jit(vm: Vm, start: str) -> bool {
    f = find_func(vm, start);
    if f is None { return False; }
    if f.is_jit == False { return False; }
    w = f spawn JitCheck();
    return w.ok;
}
def can_compile(vm: Vm, start: str) -> bool { return can_jit(vm, start); }
def is_jit_eligible(vm: Vm, start: str) -> bool { return can_jit(vm, start); }
def vm_can_jit(vm: Vm, start: str) -> bool { return can_jit(vm, start); }

test "diamond_revisit_collects_all" {
    vm = make_vm();
    add_func(vm, "A", 2, True);
    add_func(vm, "B", 1, True);
    add_func(vm, "C", 1, True);
    add_func(vm, "D", 0, True);
    # insertion order forces revisit before deeper first-visit: A->C then A->B
    add_call(vm, "A", "C", 1);
    add_call(vm, "A", "B", 1);
    add_call(vm, "B", "D", 0);
    add_call(vm, "C", "D", 0);
    res = reachable(vm, "A");
    assert (sorted(res) == sorted(["A", "B", "C", "D"]));
}

test "cycle_terminates_with_claim_map" {
    vm = make_vm();
    add_func(vm, "X", 1, True);
    add_func(vm, "Y", 1, True);
    add_call(vm, "X", "Y", 1);
    add_call(vm, "Y", "X", 1);
    res = reachable(vm, "X");
    assert (sorted(res) == sorted(["X", "Y"]));
    assert (can_jit(vm, "X") == True);
}

test "unknown_id_tolerance" {
    vm = make_vm();
    add_func(vm, "A", 1, True);
    res = reachable(vm, "NOPE");
    assert (res == []);
    assert (can_jit(vm, "NOPE") == False);
    assert (add_call(vm, "A", "MISSING", 1) == False);
    assert (add_call(vm, "MISSING", "A", 1) == False);
}

test "bail_on_non_jit_array_or_bool" {
    vm = make_vm();
    add_func(vm, "caller", 2, True);
    add_func(vm, "good", 2, True);
    add_func_ex(vm, "not_jit", 2, False, 0, False);
    add_func_ex(vm, "with_array", 2, True, 1, False);
    add_func_ex(vm, "bool_ret", 2, True, 0, True);
    add_call(vm, "caller", "good", 2);
    assert (can_jit(vm, "caller") == True);
    vm2 = make_vm();
    add_func(vm2, "caller", 2, True);
    add_func_ex(vm2, "not_jit", 2, False, 0, False);
    add_call(vm2, "caller", "not_jit", 2);
    assert (can_jit(vm2, "caller") == False);
    vm3 = make_vm();
    add_func(vm3, "caller", 2, True);
    add_func_ex(vm3, "with_array", 2, True, 1, False);
    add_call(vm3, "caller", "with_array", 2);
    assert (can_jit(vm3, "caller") == False);
    vm4 = make_vm();
    add_func(vm4, "caller", 2, True);
    add_func_ex(vm4, "bool_ret", 2, True, 0, True);
    add_call(vm4, "caller", "bool_ret", 2);
    assert (can_jit(vm4, "caller") == False);
}

test "arity_mismatch_bails" {
    vm = make_vm();
    add_func(vm, "caller", 2, True);
    add_func(vm, "callee", 2, True);
    add_call(vm, "caller", "callee", 1);
    assert (can_jit(vm, "caller") == False);
    vm2 = make_vm();
    add_func(vm2, "caller", 2, True);
    add_func(vm2, "callee", 2, True);
    add_call(vm2, "caller", "callee", 2);
    assert (can_jit(vm2, "caller") == True);
}

test "transitive_bail_and_self_call" {
    vm = make_vm();
    add_func(vm, "root", 1, True);
    add_func(vm, "mid", 1, True);
    add_func_ex(vm, "leaf_bad", 1, True, 0, True);
    add_call(vm, "root", "mid", 1);
    add_call(vm, "mid", "leaf_bad", 1);
    assert (can_jit(vm, "root") == False);
    vm2 = make_vm();
    add_func(vm2, "self", 1, True);
    add_call(vm2, "self", "self", 1);
    res2 = reachable(vm2, "self");
    assert (sorted(res2) == sorted(["self"]));
    assert (can_jit(vm2, "self") == True);
}
