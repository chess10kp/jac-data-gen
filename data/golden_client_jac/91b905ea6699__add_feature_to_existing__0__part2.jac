node Task {
    has title: str,
        done: bool = False;
}

node ShoppingItem {
    has name: str,
        cost: float;
}

"""Get all tasks."""
def:pub get_tasks -> list[Task] {
    return [root-->][?:Task];
}

"""Get the current shopping list."""
def:pub get_shopping_list -> list[ShoppingItem] {
    return [root-->][?:ShoppingItem];
}

cl def:pub app -> JsxElement {
    has tasks: list = [],
        ingredients: list = [],
        loading: bool = True;

    async can with entry {
        tasks = await get_tasks();
        ingredients = await get_shopping_list();
        loading = False;
    }

    return
        <div class="container">
            <h1>Day Planner</h1>
            {(<p class="loading">Loading...</p>)
                if loading
                else <p class="summary">{len(tasks)} task(s), {len(ingredients)} item(s)</p>}
        </div>;
}
