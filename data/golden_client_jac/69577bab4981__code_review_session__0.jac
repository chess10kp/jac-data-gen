# main.jac
"""Application with Jac-native validation."""

def validate_title(title: str) -> bool {
    return len(title) > 3 and title.strip() != "";
}

def get_sample_task() -> dict {
    return {"title": "Build API"};
}

def generate_desc(title: str) -> str {
    return f"Task description for: {title}";
}

node Task {
    has title: str;
}

walker TaskCreator {
    can create with Root entry {
        task_data = get_sample_task();
        title = task_data["title"] as str;
        if validate_title(title) {
            task = Task(title=title);
            here ++> task;
            report {"created": task.title, "desc": generate_desc(task.title)};
        } else {
            report {"error": "Title invalid"};
        }
    }
}

with entry {
    root spawn TaskCreator();
}
