"""Task creation endpoint with AI categorization and priority."""

enum Category { WORK, PERSONAL, SHOPPING, HEALTH, FITNESS, OTHER }

def categorize(title: str) -> Category by llm();
sem categorize = "Categorize a task based on its title";

node Task {
    has title: str,
        done: bool = False,
        category: str = "other",
        priority: int = 3;
}

# New feature: accept an optional priority (1 = highest, 5 = lowest).
def:priv add_task(title: str, priority: int = 3) -> Task {
    category = str(categorize(title)).split(".")[-1].lower();
    clamped = 1 if priority < 1 else (5 if priority > 5 else priority);
    task = root ++> Task(title=title, category=category, priority=clamped);
    return task[0];
}
