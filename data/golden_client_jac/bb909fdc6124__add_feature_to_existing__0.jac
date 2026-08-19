"""AddTask walker extended with a priority field."""

enum Category { WORK, PERSONAL, SHOPPING, HEALTH, FITNESS, OTHER }

def categorize(title: str) -> Category by llm();
sem categorize = "Categorize a task based on its title";

node Task {
    has title: str,
        done: bool = False,
        category: str = "other",
        priority: int = 3;
}

walker AddTask {
    has title: str,
        priority: int = 3,
        reports: list[Task] = [];

    can create with Root entry {
        category = str(categorize(self.title)).split(".")[-1].lower();
        clamped = 1 if self.priority < 1 else (5 if self.priority > 5 else self.priority);
        new_task = here ++> Task(title=self.title, category=category, priority=clamped);
        report new_task[0];
    }
}
