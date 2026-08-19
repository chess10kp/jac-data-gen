async def clear_done {
    tasks = [t for t in tasks if not t.done];
}
