"""Client-side server bindings plus a task search box."""

sv import from ..main {
    Task,
    AddTask, ListTasks, ToggleTask, DeleteTask,
    GenerateShoppingList, GetShoppingList, ClearShoppingList,
    SearchTasks
}

def:pub TaskSearch -> JsxElement {
    has query: str = "",
        results: list[Task] = [];

    # New feature: run the SearchTasks walker and show matches.
    async def runSearch {
        if not query.strip() {
            results = [];
            return;
        }
        response = root spawn SearchTasks(query=query);
        results = response.reports[0] if response.reports else [];
    }

    return
        <div class="search">
            <input
                class="input"
                value={query}
                onChange={lambda e: ChangeEvent { query = e.target.value; }}
                onKeyPress={lambda e: KeyboardEvent { if e.key == "Enter" { runSearch(); } }}
                placeholder="Search tasks..."
            />
            <button onClick={lambda { runSearch(); }}>Search</button>
            {[<div key={jid(t)} class="result">{t.title}</div> for t in results]}
        </div>;
}
