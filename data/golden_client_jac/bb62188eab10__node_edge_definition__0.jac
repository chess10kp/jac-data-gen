"""Jac module with graph and AI features."""

    node Task {
        has title: str;
        has done: bool = False;
    }

    walker TaskCreator {
        has title: str;

        can create with Root entry {
            task = Task(title=self.title);
            here ++> task;
            print(f" Created: {task.title}");
        }
    }

    def generate_desc(title: str) -> str {
        return f"Task description for: {title}";
    }
