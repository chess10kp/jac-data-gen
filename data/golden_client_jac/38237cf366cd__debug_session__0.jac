def:pub get_tasks -> list[Task] {
    if not is_authenticated() {
        return [];
    }
    return [root-->][?:Task];
}
