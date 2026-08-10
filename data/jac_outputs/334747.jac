"""Select a subset of tasks from all_tasks, keeping some % from each temp."""
def get_subset_tasks(all_tasks: list[str], ratio: float) -> list[str] {
    if len(all_tasks) == 0 {
        return all_tasks;
    }
    assert 0.0 <= ratio <= 1.0;
    all_tasks = sorted(all_tasks);
    samples_to_keep = int(len(all_tasks) * ratio);
    return all_tasks[::(len(all_tasks) // samples_to_keep)][:samples_to_keep];
}