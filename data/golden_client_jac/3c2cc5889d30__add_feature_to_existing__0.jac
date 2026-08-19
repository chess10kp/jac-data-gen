async def clear_done {
    tasks = [t for t in tasks if not t.done];
}
<button onClick={clear_done}>Clear completed</button>
