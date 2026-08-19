"""Tasks column placeholder -- fetches and shows tasks."""
cl def:pub TasksColumn -> JsxElement {
    return <div class="column"><h2>Today's Tasks</h2></div>;
}

"""Shopping column placeholder -- fetches and shows the list."""
cl def:pub ShoppingColumn -> JsxElement {
    return <div class="column"><h2>Meal Shopping List</h2></div>;
}

"""Return today's date as a friendly string."""
def:pub get_today -> str {
    return "Monday, July 21";
}

cl def:pub app -> JsxElement {
    has today: str = "";

    async can with entry {
        today = await get_today();
    }

    return
        <div class="container">
            <header class="app-header">
                <h1>AI Day Planner</h1>
                {(<span class="date">{today}</span>) if today else None}
            </header>
            <div class="two-column">
                <TasksColumn/>
                <ShoppingColumn/>
            </div>
            <footer class="app-footer">Built with Jac</footer>
        </div>;
}
