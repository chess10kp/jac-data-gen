"""Jac module with graph and AI features."""

node Task {
    has title: str;
    has done: bool = False;
    has desc: str = "";
}

def generate_desc(title: str) -> str {
    return f"Task description for: {title}";
}

walker TaskCreator {
    has title: str;

    can create with Root entry {
        task = Task(title=self.title, desc=generate_desc(self.title));
        here ++> task;
        report {"title": task.title, "desc": task.desc};
    }
}
