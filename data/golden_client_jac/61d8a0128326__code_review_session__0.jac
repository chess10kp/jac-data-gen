# main.jac
"""Main application."""

node Task {
    has title: str;
}

def validate_title(title: str) -> bool {
    return len(title) > 3;
}

def generate_desc(title: str) -> str {
    return f"Task description for: {title}";
}

walker TaskCreator {
    has title: str;

    can create with Root entry {
        if validate_title(self.title) {
            task = Task(title=self.title);
            here ++> task;
            report {"created": task.title, "desc": generate_desc(task.title)};
        } else {
            report {"error": "Title too short"};
        }
    }
}

with entry {
    root spawn TaskCreator(title="Build API");
}
