def:pub get_tasks -> list {
    if not current_user() { raise Exception("unauthorized"); }
    ...;
}
