"""Main application."""
    import models, utils;

    walker TaskCreator {
        has title: str;

        can create with Root entry {
            if utils.validate_title(self.title) {
                task = models.Task(title=self.title);
                here ++> task;
                desc = utils.generate_desc(self.title);
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
