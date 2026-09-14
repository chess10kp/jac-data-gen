"""Teck-Lab/Teck.Monorepo#482: optimize agent context and workflow ownership."""

node ContextItem {
    has key: str;
    has kind: str;
}

edge Contains {}

walker ContextClosure {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with ContextItem entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        self.found.append(here.key);
        print(here.key);
        for kid in [here ->:Contains:->][?:ContextItem] {
            visit :0: [kid];
        }
    }
}

def collect_context(start_node: ContextItem) -> list[str] {
    w = start_node spawn ContextClosure(claimed={});
    return sorted(w.found);
}

def canonical_context() -> list[str] {
    graph_root = ContextItem(key="AGENTS.md", kind="repository-rules");
    claude_adapter = ContextItem(key="claude-adapter", kind="agent-adapter");
    skills_node = ContextItem(key="Teck skills", kind="task-procedures");
    dotnet = ContextItem(key="teck-dotnet-service-scaffold", kind="skill");
    messaging = ContextItem(key="teck-messaging", kind="skill");
    orca = ContextItem(key="Orca", kind="coordination");
    memory = ContextItem(key="AgentMemory", kind="cross-session-memory");
    mcp = ContextItem(key="external MCP", kind="integration");
    hooks = ContextItem(key="deterministic hooks", kind="enforcement");

    graph_root +>:Contains:+> claude_adapter;
    graph_root +>:Contains:+> skills_node;
    graph_root +>:Contains:+> orca;
    graph_root +>:Contains:+> memory;
    graph_root +>:Contains:+> mcp;
    skills_node +>:Contains:+> dotnet;
    skills_node +>:Contains:+> messaging;
    orca +>:Contains:+> hooks;

    return collect_context(graph_root);
}

def plugin_treatment(plugin_name: str) -> str {
    if plugin_name == "C# LSP" {
        return "keep";
    }
    if plugin_name == "TypeScript LSP" {
        return "keep";
    }
    if plugin_name == "Claude HUD" {
        return "keep";
    }
    if plugin_name == "Microsoft Docs" {
        return "keep";
    }
    if plugin_name == "Playwright" {
        return "task-scope";
    }
    if plugin_name == "Frontend Design" {
        return "task-scope";
    }
    if plugin_name == "Security Guidance" {
        return "task-scope";
    }
    if plugin_name == "GitHub" {
        return "review";
    }
    if plugin_name == "Superpowers" {
        return "disable";
    }
    return "review";
}

def skill_is_task_scoped(skill_name: str) -> bool {
    if skill_name == "teck-dotnet-service-scaffold" {
        return True;
    }
    if skill_name == "teck-ef-migration" {
        return True;
    }
    if skill_name == "teck-messaging" {
        return True;
    }
    if skill_name == "teck-multi-tenancy" {
        return True;
    }
    if skill_name == "teck-endpoint-pattern" {
        return True;
    }
    if skill_name == "teck-container-publish" {
        return True;
    }
    if skill_name == "teck-frontend-api-integration" {
        return True;
    }
    return False;
}

def token_reduction(before_tokens: int, after_tokens: int) -> int {
    if before_tokens > after_tokens {
        return before_tokens - after_tokens;
    }
    return 0;
}

def workflow_owner(capability: str) -> str {
    if capability == "coordination" {
        return "Orca";
    }
    if capability == "worktrees" {
        return "Orca";
    }
    if capability == "Dispatches" {
        return "Orca";
    }
    if capability == "workflow_state" {
        return "Orca";
    }
    if capability == "repository_rules" {
        return "AGENTS.md";
    }
    if capability == "task_procedure" {
        return "Teck skills";
    }
    if capability == "memory" {
        return "AgentMemory";
    }
    if capability == "external_docs" {
        return "MCP";
    }
    return "unknown";
}

test "diamond revisit still reaches sibling" {
    a = ContextItem(key="a", kind="fixture");
    b = ContextItem(key="b", kind="fixture");
    c = ContextItem(key="c", kind="fixture");
    d = ContextItem(key="d", kind="fixture");
    e = ContextItem(key="e", kind="fixture");

    a +>:Contains:+> c;
    a +>:Contains:+> b;
    b +>:Contains:+> d;
    c +>:Contains:+> e;
    c +>:Contains:+> d;

    assert (collect_context(a) == ["a", "b", "c", "d", "e"]);
}

test "cycle revisit is skipped without truncating traversal" {
    a = ContextItem(key="a", kind="fixture");
    b = ContextItem(key="b", kind="fixture");
    c = ContextItem(key="c", kind="fixture");

    a +>:Contains:+> b;
    b +>:Contains:+> c;
    c +>:Contains:+> a;

    assert (collect_context(a) == ["a", "b", "c"]);
}

test "unknown identifiers are tolerated" {
    assert (plugin_treatment("Unlisted plugin") == "review");
    assert (workflow_owner("unmapped capability") == "unknown");
    assert (skill_is_task_scoped("random-skill") == False);
}

test "context and measurement edge cases" {
    items = canonical_context();

    assert (len(items) == 9);
    assert (items[0] == "AGENTS.md");
    assert (token_reduction(100, 70) == 30);
    assert (token_reduction(70, 100) == 0);
    assert (token_reduction(0, 0) == 0);
    assert (plugin_treatment("Superpowers") == "disable");
}
