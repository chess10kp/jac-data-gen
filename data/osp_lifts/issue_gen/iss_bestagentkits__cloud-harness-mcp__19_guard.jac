obj AgentStore {
    has agents: dict[str, Agent] = {};
    has workspaces: dict[str, Workspace] = {};
    has idempotency: dict[str, str] = {};
    has allowed_models: list[str] = ["default"];
    has allowed_providers: list[str] = ["pi"];
    has allowed_tools: list[str] = ["read", "write", "search"];
}

node Workspace {
    has workspace_id: str;
    has principal_id: str;
}

node Agent {
    has agent_id: str;
    has principal_id: str;
    has workspace_id: str;
    has lineage_id: str;
    has status: str = "running";
    has ttl: int = 60;
    has output_budget: int = 1000;
    has token_budget: int = 10000;
    has cost_budget: int = 100;
    has model: str = "default";
    has provider: str = "pi";
    has tools: list[str] = [];
    has logs: list[str] = [];
    has network_policy: str = "deny";
    has credential_scope: str = "workspace";
    has docker_socket: bool = False;
}

edge ParentChild {}
edge AgentInWorkspace {}

walker Descendants {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can collect with Agent entry {
        if here.agent_id in self.claimed {
            skip;
        }
        self.claimed[here.agent_id] = True;
        self.found.append(here.agent_id);
        print(here.agent_id);
        for kid in [here ->:ParentChild:->][?:Agent] {
            visit :0: [kid];
        }
    }
}

def agent_spawn(
    store: AgentStore,
    agent_id: str,
    principal_id: str,
    workspace_id: str,
    parent_id: str = "",
    ttl: int = 60,
    output_budget: int = 1000,
    token_budget: int = 10000,
    cost_budget: int = 100,
    model: str = "default",
    provider: str = "pi",
    tools: list[str] | None = None,
    idempotency_key: str = ""
) -> dict[str, str] {
    if agent_id == "" {
        return {"id": "", "status": "rejected"};
    }
    if ttl <= 0 or output_budget < 0 or token_budget < 0 or cost_budget < 0 {
        return {"id": agent_id, "status": "rejected"};
    }
    if model not in store.allowed_models or provider not in store.allowed_providers {
        return {"id": agent_id, "status": "rejected"};
    }
    if idempotency_key != "" and idempotency_key in store.idempotency {
        old_id = store.idempotency[idempotency_key];
        old = store.agents[old_id];
        if old.principal_id == principal_id and old.workspace_id == workspace_id {
            return {"id": old_id, "status": "existing"};
        }
        return {"id": "", "status": "conflict"};
    }
    if agent_id in store.agents {
        return {"id": agent_id, "status": "exists"};
    }

    requested_tools: list[str] = [];
    if tools is not None {
        requested_tools = tools;
    }
    for tool_name in requested_tools {
        if tool_name not in store.allowed_tools {
            return {"id": agent_id, "status": "rejected"};
        }
    }

    parent: Agent | None = None;
    if parent_id != "" {
        if parent_id not in store.agents {
            return {"id": agent_id, "status": "rejected"};
        }
        parent = store.agents[parent_id];
        if parent.principal_id != principal_id or parent.workspace_id != workspace_id {
            return {"id": agent_id, "status": "denied"};
        }
    }

    ws: Workspace;
    if workspace_id in store.workspaces {
        ws = store.workspaces[workspace_id];
        if ws.principal_id != principal_id {
            return {"id": agent_id, "status": "denied"};
        }
    } else {
        ws = Workspace(workspace_id=workspace_id, principal_id=principal_id);
        store.workspaces[workspace_id] = ws;
    }

    lineage_id: str = agent_id;
    if parent is not None {
        lineage_id = parent.lineage_id;
    }
    ag = Agent(
        agent_id=agent_id,
        principal_id=principal_id,
        workspace_id=workspace_id,
        lineage_id=lineage_id,
        ttl=ttl,
        output_budget=output_budget,
        token_budget=token_budget,
        cost_budget=cost_budget,
        model=model,
        provider=provider,
        tools=requested_tools
    );
    ag +>:AgentInWorkspace:+> ws;
    if parent is not None {
        parent +>:ParentChild:+> ag;
    }
    store.agents[agent_id] = ag;
    if idempotency_key != "" {
        store.idempotency[idempotency_key] = agent_id;
    }
    return {"id": agent_id, "status": "created"};
}

def agent_status(
    store: AgentStore,
    principal_id: str,
    workspace_id: str,
    agent_id: str
) -> dict[str, str] {
    if agent_id not in store.agents {
        return {"id": agent_id, "status": "unknown"};
    }
    ag = store.agents[agent_id];
    if ag.principal_id != principal_id or ag.workspace_id != workspace_id {
        return {"id": agent_id, "status": "unknown"};
    }
    return {"id": agent_id, "status": ag.status};
}

def agent_logs(
    store: AgentStore,
    principal_id: str,
    workspace_id: str,
    agent_id: str
) -> list[str] {
    empty_logs: list[str] = [];
    if agent_id not in store.agents {
        return empty_logs;
    }
    ag = store.agents[agent_id];
    if ag.principal_id != principal_id or ag.workspace_id != workspace_id {
        return empty_logs;
    }
    return ag.logs;
}

def agent_message(
    store: AgentStore,
    principal_id: str,
    workspace_id: str,
    agent_id: str,
    message: str
) -> dict[str, str] {
    if agent_id not in store.agents {
        return {"id": agent_id, "status": "unknown"};
    }
    ag = store.agents[agent_id];
    if ag.principal_id != principal_id or ag.workspace_id != workspace_id {
        return {"id": agent_id, "status": "unknown"};
    }
    if ag.status != "running" {
        return {"id": agent_id, "status": "closed"};
    }
    if len(ag.logs) >= 8 {
        ag.logs = ag.logs[1:];
    }
    ag.logs.append(message);
    return {"id": agent_id, "status": "accepted"};
}

def agent_cancel(
    store: AgentStore,
    principal_id: str,
    workspace_id: str,
    agent_id: str
) -> dict[str, str] {
    if agent_id not in store.agents {
        return {"id": agent_id, "status": "unknown"};
    }
    root_node = store.agents[agent_id];
    if root_node.principal_id != principal_id or root_node.workspace_id != workspace_id {
        return {"id": agent_id, "status": "unknown"};
    }

    w = root_node spawn Descendants(claimed={});
    for descendant_id in w.found {
        if descendant_id in store.agents {
            child = store.agents[descendant_id];
            if child.principal_id == principal_id and child.workspace_id == workspace_id {
                child.status = "cancelled";
            }
        }
    }
    return {"id": agent_id, "status": "cancelled"};
}

def agent_list(
    store: AgentStore,
    principal_id: str,
    workspace_id: str
) -> list[str] {
    ids: list[str] = [];
    for agent_id in store.agents {
        ag = store.agents[agent_id];
        if ag.principal_id == principal_id and ag.workspace_id == workspace_id {
            ids.append(agent_id);
        }
    }
    return sorted(ids);
}

test "diamond cancellation claims each node once" {
    store = AgentStore();
    agent_spawn(store, "r", "p", "w");
    agent_spawn(store, "left", "p", "w");
    agent_spawn(store, "right", "p", "w");
    agent_spawn(store, "shared", "p", "w");
    root_node: Agent = store.agents["r"];
    left_node: Agent = store.agents["left"];
    right_node: Agent = store.agents["right"];
    shared_node: Agent = store.agents["shared"];
    root_node +>:ParentChild:+> right_node;
    root_node +>:ParentChild:+> left_node;
    left_node +>:ParentChild:+> shared_node;
    right_node +>:ParentChild:+> shared_node;
    w = root_node spawn Descendants(claimed={});
    assert (sorted(w.found) == ["left", "r", "right", "shared"]);
    answer = agent_cancel(store, "p", "w", "r");
    assert (answer["status"] == "cancelled");
    assert (agent_status(store, "p", "w", "shared")["status"] == "cancelled");
}

test "unknown ids are tolerated" {
    store = AgentStore();
    assert (agent_status(store, "p", "w", "missing")["status"] == "unknown");
    assert (agent_logs(store, "p", "w", "missing") == []);
    assert (agent_message(store, "p", "w", "missing", "hello")["status"] == "unknown");
    assert (agent_cancel(store, "p", "w", "missing")["status"] == "unknown");
    assert (agent_list(store, "p", "w") == []);
}

test "idempotency and workspace isolation are enforced" {
    store = AgentStore();
    first = agent_spawn(store, "a", "p1", "w1", "", 20, 100, 100, 10, "default", "pi", None, "key");
    again = agent_spawn(store, "b", "p1", "w1", "", 20, 100, 100, 10, "default", "pi", None, "key");
    conflict = agent_spawn(store, "b", "p2", "w2", "", 20, 100, 100, 10, "default", "pi", None, "key");
    foreign = agent_status(store, "p2", "w2", "a");
    assert (first["status"] == "created");
    assert (again["id"] == "a" and again["status"] == "existing");
    assert (conflict["status"] == "conflict");
    assert (foreign["status"] == "unknown");
}

test "bounded logs and admission policy work" {
    store = AgentStore();
    created = agent_spawn(store, "a", "p", "w", "", 20, 100, 100, 10, "default", "pi", ["read"], "logs");
    bad_ttl = agent_spawn(store, "bad", "p", "w", "", 0);
    bad_tool = agent_spawn(store, "tool", "p", "w", "", 20, 100, 100, 10, "default", "pi", ["shell"], "tool");
    agent_message(store, "p", "w", "a", "1");
    agent_message(store, "p", "w", "a", "2");
    agent_message(store, "p", "w", "a", "3");
    agent_message(store, "p", "w", "a", "4");
    agent_message(store, "p", "w", "a", "5");
    agent_message(store, "p", "w", "a", "6");
    agent_message(store, "p", "w", "a", "7");
    agent_message(store, "p", "w", "a", "8");
    agent_message(store, "p", "w", "a", "9");
    logs = agent_logs(store, "p", "w", "a");
    assert (created["status"] == "created");
    assert (bad_ttl["status"] == "rejected");
    assert (bad_tool["status"] == "rejected");
    assert (len(logs) == 8);
    assert (logs[7] == "9");
    assert (agent_list(store, "p", "w") == ["a"]);
}
