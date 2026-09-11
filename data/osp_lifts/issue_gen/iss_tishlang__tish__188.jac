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
