def split_tasks(task_string: Any) -> object {
    tasks = task_string.split(' ');
    cleaned_tasks = [];
    for task in tasks {
        if ('(' in task) {
            start_index = task.index('(');
            end_index = task.index(')');
            cleaned_task = task[:start_index] + task[(end_index + 1):];
            cleaned_tasks.append(cleaned_task);
        } else {
            cleaned_tasks.append(task);
        }
    }
    return cleaned_tasks;
}



with entry {
    print(split_tasks('hello'));
    print(split_tasks('Racecar'));
    print(split_tasks('abcabc'));
}
