# main.jac
node Task {
    has title: str;
}

def validate_title(title: str) -> bool {
    return len(title) > 3;
}

walker TaskCreator {
    has title: str;

    can create with Root entry {
        if validate_title(self.title) {
            task = Task(title=self.title);
            here ++> task;
            report {"created": task.title};
        } else {
            report {"error": "Title too short"};
        }
    }
}

with entry {
    root spawn TaskCreator(title="Build API");
}
