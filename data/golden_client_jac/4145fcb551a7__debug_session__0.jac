def:pub get_tasks -> list[Task] {
    if not current_user() { raise Exception("unauthorized"); }
    return [root-->][?:Task];
}
