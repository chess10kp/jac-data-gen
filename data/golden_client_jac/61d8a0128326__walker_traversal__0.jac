"""Main application - imports Python module."""
    import models;
    import validators;

    def generate_desc(title: str) -> str {
        return f"Task description for: {title}";
    }

    walker TaskCreator {
        has title: str;

        can create with Root entry {
            # Call Python module functions
            if validators.validate_title(self.title) {
                task = models.Task(title=self.title);
                here ++> task;
                desc = generate_desc(task.title);
                print(f" Created: {task.title}");
                print(f"  AI: {desc}");
            } else {
                print(" Title too short!");
            }
        }
    }

    with entry {
        root spawn TaskCreator(title="Build API");
    }
