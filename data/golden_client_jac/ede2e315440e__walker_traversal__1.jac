walker AddTask {
    has title: str;

    can create with Root entry {
        category = str(categorize(self.title)).split(".")[-1].lower();
        new_task = here ++> Task(
            title=self.title,
            category=category
        );
        report new_task[0];
    }
}
