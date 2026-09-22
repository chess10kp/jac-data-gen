"""Helper function to select plottable tasks. Used inside the doNd functions."""
def _select_plottables(tasks: object) -> tuple[object, ...] {
    if not hasattr(tasks, '__iter__') {
        tasks = (tasks,);
    }
    plottables = [task for task in tasks if hasattr(task, '_instrument')];
    return tuple(plottables);
}