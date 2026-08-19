"""AddTask walker with an optional due date."""

enum Category { WORK, PERSONAL, SHOPPING, HEALTH, FITNESS, OTHER }

def categorize(title: str) -> Category by llm();
sem categorize = "Categorize a task based on its title";

node Task {
    has title: str,
        done: bool = False,
        category: str = "other",
        due_date: str = "";
}

walker AddTask {
    has title: str,
        due_date: str = "";

    can create with Root entry {
        category = str(categorize(self.title)).split(".")[-1].lower();
        new_task = here ++> Task(
            title=self.title,
            category=category,
            due_date=self.due_date
        );
        report new_task[0];
    }
}
