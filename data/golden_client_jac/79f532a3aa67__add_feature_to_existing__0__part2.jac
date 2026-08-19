sv import from ..main { Task, Note, get_tasks, get_shopping_list, get_notes }

def:pub DayPlanner -> JsxElement {
    has isLoggedIn: bool = False,
        tasks: list[Task] = [],
        shopping: list = [],
        notes: list[Note] = [];

    async def fetchTasks { tasks = await get_tasks(); }
    async def fetchShoppingList { shopping = await get_shopping_list(); }
    async def fetchNotes { notes = await get_notes(); }

    # New feature: also load the user's notes once they are logged in.
    can with [isLoggedIn] entry {
        if isLoggedIn {
            fetchTasks();
            fetchShoppingList();
            fetchNotes();
        }
    }

    return
        <div class="planner">
            <button onClick={lambda { isLoggedIn = not isLoggedIn; }}>Toggle login</button>
            <p>{len(tasks)} tasks, {len(notes)} notes</p>
        </div>;
}
