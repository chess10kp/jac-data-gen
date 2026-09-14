"""OSP cascade record for Growth-Circle/cadis#1006."""

node Agent {
    has agent_id: str;
    has parent_agent_id: str = "";
    has agent_depth: int = 0;
    has child_count: int = 0;
    has alive: bool = True;
}

node WorkspaceGrant {
    has workspace: str;
    has revoked: bool = False;
}

node AgentHome {
    has present: bool = True;
}

edge Child {}
edge Grant {}
edge Home {}

obj AgentRuntime {
    has agents: dict[str, Agent] = {};
    has max_total_agents: int = 100;
    has max_children_per_parent: int = 4;
    has max_depth: int = 2;
    has grants_persisted: bool = False;
}

walker CascadeWalker {
    has claimed: dict[str, bool] = {};
    has found: list[Agent] = [];

    can collect with Agent entry {
        if here.agent_id in self.claimed { skip; }
        self.claimed[here.agent_id] = True;
        self.found.append(here);
        print here.agent_id;
        for kid in [here ->:Child:->][?:Agent] {
            visit :0: [kid];
        }
    }
}

walker DepthWalker {
    has target_id: str;
    has claimed: dict[str, bool] = {};
    has found_depth: int = -1;

    can inspect with Agent entry {
        if here.agent_id in self.claimed { skip; }
        self.claimed[here.agent_id] = True;
        if here.agent_id == self.target_id {
            self.found_depth = here.agent_depth;
        }
        print here.agent_id;
        for kid in [here ->:Child:->][?:Agent] {
            visit :0: [kid];
        }
    }
}

def new_runtime(
    max_total_agents: int = 100,
    max_children_per_parent: int = 4,
    max_depth: int = 2
) -> AgentRuntime {
    runtime = AgentRuntime(
        max_total_agents=max_total_agents,
        max_children_per_parent=max_children_per_parent,
        max_depth=max_depth
    );
    main_agent = Agent(agent_id="main", agent_depth=0);
    runtime.agents["main"] = main_agent;
    return runtime;
}

def spawn_agent_record(
    runtime: AgentRuntime,
    agent_id: str,
    parent_agent_id: str = "main"
) -> bool {
    if agent_id in runtime.agents {
        return False;
    }
    if len(runtime.agents) >= runtime.max_total_agents {
        return False;
    }
    if parent_agent_id not in runtime.agents {
        return False;
    }
    parent_agent = runtime.agents[parent_agent_id];
    if not parent_agent.alive {
        return False;
    }
    if parent_agent.child_count >= runtime.max_children_per_parent {
        return False;
    }
    if parent_agent.agent_depth + 1 > runtime.max_depth {
        return False;
    }
    child_agent = Agent(
        agent_id=agent_id,
        parent_agent_id=parent_agent_id,
        agent_depth=parent_agent.agent_depth + 1
    );
    home = AgentHome();
    parent_agent +>:Child:+> child_agent;
    child_agent +>:Home:+> home;
    runtime.agents[agent_id] = child_agent;
    parent_agent.child_count += 1;
    return True;
}

def connect_parent(
    runtime: AgentRuntime,
    parent_agent_id: str,
    child_agent_id: str
) -> bool {
    if parent_agent_id not in runtime.agents {
        return False;
    }
    if child_agent_id not in runtime.agents {
        return False;
    }
    parent_agent = runtime.agents[parent_agent_id];
    child_agent = runtime.agents[child_agent_id];
    parent_agent +>:Child:+> child_agent;
    child_agent.parent_agent_id = parent_agent_id;
    parent_agent.child_count += 1;
    return True;
}

def agent_depth(runtime: AgentRuntime, agent_id: str) -> int {
    if agent_id not in runtime.agents {
        return -1;
    }
    main_agent = runtime.agents["main"];
    w = main_agent spawn DepthWalker(target_id=agent_id, claimed={});
    return w.found_depth;
}

def grant_workspace(
    runtime: AgentRuntime,
    agent_id: str,
    workspace: str
) -> bool {
    if agent_id not in runtime.agents {
        return False;
    }
    agent = runtime.agents[agent_id];
    if not agent.alive {
        return False;
    }
    grant = WorkspaceGrant(workspace=workspace);
    agent +>:Grant:+> grant;
    runtime.grants_persisted = True;
    return True;
}

def workspace_grants(
    runtime: AgentRuntime,
    agent_id: str
) -> list[str] {
    values: list[str] = [];
    if agent_id not in runtime.agents {
        return values;
    }
    agent = runtime.agents[agent_id];
    for grant in [agent ->:Grant:->][?:WorkspaceGrant] {
        if not grant.revoked {
            values.append(grant.workspace);
        }
    }
    return sorted(values);
}

def revoke_workspace_grants(
    runtime: AgentRuntime,
    agent_id: str
) -> int {
    count = 0;
    if agent_id not in runtime.agents {
        return count;
    }
    agent = runtime.agents[agent_id];
    for grant in [agent ->:Grant:->][?:WorkspaceGrant] {
        if not grant.revoked {
            grant.revoked = True;
            count += 1;
        }
    }
    return count;
}

def persist_workspace_grants(runtime: AgentRuntime) -> None {
    runtime.grants_persisted = True;
}

def agent_home_exists(
    runtime: AgentRuntime,
    agent_id: str
) -> bool {
    if agent_id not in runtime.agents {
        return False;
    }
    agent = runtime.agents[agent_id];
    for home in [agent ->:Home:->][?:AgentHome] {
        if home.present {
            return True;
        }
    }
    return False;
}

def kill_agent(
    runtime: AgentRuntime,
    agent_id: str
) -> list[str] {
    removed: list[str] = [];
    if agent_id == "main" {
        return removed;
    }
    if agent_id not in runtime.agents {
        return removed;
    }

    target_agent = runtime.agents[agent_id];
    w = target_agent spawn CascadeWalker(claimed={});
    for victim in w.found {
        if victim.agent_id in runtime.agents {
            removed.append(victim.agent_id);
        }
    }

    removed.reverse();
    for victim_id in removed {
        victim = runtime.agents[victim_id];
        revoke_workspace_grants(runtime, victim_id);
        for home in [victim ->:Home:->][?:AgentHome] {
            home.present = False;
        }
        if victim.parent_agent_id in runtime.agents {
            parent_agent = runtime.agents[victim.parent_agent_id];
            if parent_agent.child_count > 0 {
                parent_agent.child_count -= 1;
            }
        }
        victim.alive = False;
        print "agent.killed";
        del runtime.agents[victim_id];
    }
    persist_workspace_grants(runtime);
    return removed;
}
