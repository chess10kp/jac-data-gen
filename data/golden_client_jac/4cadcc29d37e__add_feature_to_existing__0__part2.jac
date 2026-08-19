import from byllm.lib { Model }

glob llm = Model(model_name="gpt-4o");

node Place {
    has name: str = "";
}

walker AIAgent {
    has goal: str;
    has memory: list = [];
    has steps: int = 0;
    has max_steps: int = 10;

    can decide with Place entry {
        self.steps += 1;
        context = f"Goal: {self.goal}\nCurrent: {here.name}\nMemory: {self.memory}";
        decision = context by llm("Decide next action");
        self.memory.append({"location": here.name, "decision": decision});
        if self.steps >= self.max_steps {
            disengage;
        }
        visit [-->];
    }
}
