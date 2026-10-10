node Goal {
    has title: str;
    has scenario: str;
    has status: str = "active";
}

node Task {
    has title: str;
    has tool: str;
    has owner: str;
    has status: str = "pending";
}

node Memory {
    has kind: str;
    has value: str;
}

edge links;
edge executes;
edge updates;

walker GraphPlanner {
    has goal: str;
    has scenario: str;

    can init with Root entry {
        here ++> Goal(title=goal, scenario=scenario);
    }
}

walker TaskGenerator {
    has title: str;
    has tool: str;
    has owner: str;

    can create with Goal entry {
        here ++> Task(title=title, tool=tool, owner=owner);
    }
}

walker Executor {
    can execute with Task entry {
        here.status = "complete";
        here ++> Memory(kind="artifact", value="Completed: " + here.title);
    }
}

walker MemoryTraverse {
    has objective: str;

    can update_memory with Root entry {
        here ++> Memory(kind="insight", value=objective);
    }
}
