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
    
    can init with `root {
        spawn here ++> Goal(title=self.goal, scenario=self.scenario);
    }
}

walker TaskGenerator {
    has title: str;
    has tool: str;
    has owner: str;

    can create with Goal {
        spawn here ++> Task(title=self.title, tool=self.tool, owner=self.owner);
    }
}

walker Executor {
    can execute with Task {
        self.status = "complete";
        spawn here ++> Memory(kind="artifact", value="Completed: " + self.title);
    }
}

walker MemoryTraverse {
    has objective: str;

    can update_memory with `root {
        spawn here ++> Memory(kind="insight", value=self.objective);
    }
}
