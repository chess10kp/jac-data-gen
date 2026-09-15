"""splendor-kernel/kernel#417 — sub-agent templates and topology constraints."""

node Template {
    has tid: str;
    has role: str;
    has max_depth: int;
    has max_fanout: int;
    has allows_self: bool;
}

node Instance {
    has iid: str;
    has template_id: str;
}

edge SubAgent {}

node AgentRegistry {
    has templates: dict[str, Template] = {};
    has instances: dict[str, Instance] = {};
}

walker CollectDescendants {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Instance entry {
        if here.iid in self.claimed {
            skip;
        }
        self.claimed[here.iid] = True;
        self.found.append(here.iid);
        print(here.iid);
        kids: list[Instance] = [];
        for ch in [here ->:SubAgent:->][?:Instance] {
            kids.append(ch);
        }
        for kid in kids {
            visit :0: [kid];
        }
    }
}

walker ValidateTopology {
    has templates: dict[str, Template] = {};
    has claimed: dict[str, bool] = {};
    has depth_stack: list[int] = [];
    has cycle_found: bool = False;
    has depth_exceeded: bool = False;
    has fanout_exceeded: bool = False;
    has self_violation: bool = False;

    can step with Instance entry {
        if here.iid in self.claimed {
            self.cycle_found = True;
            skip;
        }
        self.claimed[here.iid] = True;
        node_depth: int = 0;
        if len(self.depth_stack) > 0 {
            node_depth = self.depth_stack[len(self.depth_stack) - 1];
        }
        print(here.iid, node_depth);
        kids: list[Instance] = [];
        for ch in [here ->:SubAgent:->][?:Instance] {
            kids.append(ch);
        }
        if here.template_id in self.templates {
            tmpl = self.templates[here.template_id];
            if node_depth > tmpl.max_depth {
                self.depth_exceeded = True;
            }
            if len(kids) > tmpl.max_fanout {
                self.fanout_exceeded = True;
            }
            for kid in kids {
                if kid.template_id == here.template_id and not tmpl.allows_self {
                    self.self_violation = True;
                }
            }
        }
        for kid in kids {
            next_stack: list[int] = [];
            for d in self.depth_stack {
                next_stack.append(d);
            }
            next_stack.append(node_depth + 1);
            self.depth_stack = next_stack;
            visit :0: [kid];
            pop_stack: list[int] = [];
            lim: int = len(self.depth_stack) - 1;
            for i in range(lim) {
                pop_stack.append(self.depth_stack[i]);
            }
            self.depth_stack = pop_stack;
        }
    }
}

def make_registry() -> AgentRegistry {
    reg = AgentRegistry();
    root ++> reg;
    return reg;
}

def register_template(
    reg: AgentRegistry,
    tid: str,
    role: str,
    max_depth: int,
    max_fanout: int,
    allows_self: bool,
) -> None {
    if tid in reg.templates {
        return;
    }
    tmpl = Template(
        tid=tid,
        role=role,
        max_depth=max_depth,
        max_fanout=max_fanout,
        allows_self=allows_self,
    );
    root ++> tmpl;
    reg.templates[tid] = tmpl;
}

def register_instance(reg: AgentRegistry, iid: str, template_id: str) -> bool {
    if iid in reg.instances {
        return False;
    }
    if template_id not in reg.templates {
        return False;
    }
    inst = Instance(iid=iid, template_id=template_id);
    root ++> inst;
    reg.instances[iid] = inst;
    return True;
}

def link_subagent(reg: AgentRegistry, parent_id: str, child_id: str) -> bool {
    if parent_id not in reg.instances {
        return False;
    }
    if child_id not in reg.instances {
        return False;
    }
    parent_inst = reg.instances[parent_id];
    child_inst = reg.instances[child_id];
    parent_inst +>:SubAgent:+> child_inst;
    return True;
}

def validate_topology(reg: AgentRegistry, root_id: str) -> dict[str, bool] {
    out: dict[str, bool] = {};
    if root_id not in reg.instances {
        out["valid"] = False;
        out["unknown"] = True;
        out["cycle"] = False;
        out["depth_exceeded"] = False;
        out["fanout_exceeded"] = False;
        out["self_violation"] = False;
        return out;
    }
    graph_root = reg.instances[root_id];
    w = graph_root spawn ValidateTopology(templates=reg.templates, claimed={}, depth_stack=[]);
    out["unknown"] = False;
    out["cycle"] = w.cycle_found;
    out["depth_exceeded"] = w.depth_exceeded;
    out["fanout_exceeded"] = w.fanout_exceeded;
    out["self_violation"] = w.self_violation;
    out["valid"] = not (
        w.cycle_found
        or w.depth_exceeded
        or w.fanout_exceeded
        or w.self_violation
    );
    return out;
}

def list_descendants(reg: AgentRegistry, root_id: str) -> list[str] {
    empty: list[str] = [];
    if root_id not in reg.instances {
        return empty;
    }
    graph_root = reg.instances[root_id];
    w = graph_root spawn CollectDescendants(claimed={}, found=[]);
    return sorted(w.found);
}
