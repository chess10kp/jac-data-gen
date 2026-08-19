import from byllm.lib { Model }

glob llm = Model(model_name="local:gemma-4-e4b");

enum Category { WORK, PERSONAL, HEALTH, ERRANDS, OTHER }

node Task {
    has title: str,
        done: bool = False,
        category: str = "other";
}

"""Classify a task title into a category."""
def categorize(title: str) -> Category by llm();

"""Add a task with AI categorization, falling back to 'other' on failure."""
def:pub add_task(title: str) -> Task {
    category = "other";
    try {
        category = str(categorize(title)).split(".")[-1].lower();
    } except Exception as e {
        print(f"Categorization failed, using default: {e}");
    }
    task = root ++> Task(title=title, category=category);
    return task[0];
}
