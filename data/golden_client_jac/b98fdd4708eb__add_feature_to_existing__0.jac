def:pub add_task(title: str) -> Task {
    category = str(categorize(title)).split(".")[-1].lower();
    task = root ++> Task(title=title, category=category);
    return task[0];
}
