import from byllm.lib { Model }

glob llm = Model(model_name="local:gemma-4-e4b");

enum Category { WORK, PERSONAL, HEALTH, ERRANDS, OTHER }

node Task {
    has title: str,
        done: bool = False,
        category: str = "other";
}

obj Ingredient {
    has name: str,
        quantity: float,
        unit: str,
        cost: float,
        carby: bool;
}

node ShoppingItem {
    has name: str,
        quantity: float,
        unit: str,
        cost: float,
        carby: bool;
}

"""Classify a task title into a category."""
def categorize(title: str) -> Category by llm();

"""Use AI to break a meal description into a list of ingredients."""
def generate_shopping_list(meal: str) -> list[Ingredient] by llm();

"""Add a task with AI categorization."""
def:pub add_task(title: str) -> Task {
    category = str(categorize(title)).split(".")[-1].lower();
    task = root ++> Task(title=title, category=category);
    return task[0];
}

"""Get all tasks."""
def:pub get_tasks -> list[Task] {
    return [root-->][?:Task];
}

"""Toggle a task's done status."""
def:pub toggle_task(id: str) -> Task | None {
    for task in [root-->][?:Task] {
        if jid(task) == id {
            task.done = not task.done;
            return task;
        }
    }
    return None;
}

"""Delete a task."""
def:pub delete_task(id: str) -> dict[str, str] {
    for task in [root-->][?:Task] {
        if jid(task) == id {
            del task;
            return {"deleted": id};
        }
    }
    return {};
}

"""Delete every completed task and report how many were removed."""
def:pub clear_completed -> dict[str, int] {
    n = 0;
    for task in [root-->][?:Task] {
        if task.done {
            del task;
            n += 1;
        }
    }
    return {"cleared": n};
}

"""Generate a shopping list from a meal description."""
def:pub generate_list(meal: str) -> list[ShoppingItem] {
    for item in [root-->][?:ShoppingItem] {
        del item;
    }
    ingredients = generate_shopping_list(meal);
    for ing in ingredients {
        root ++> ShoppingItem(
            name=ing.name, quantity=ing.quantity,
            unit=ing.unit, cost=ing.cost, carby=ing.carby
        );
    }
    return [root-->][?:ShoppingItem];
}

"""Get the current shopping list."""
def:pub get_shopping_list -> list[ShoppingItem] {
    return [root-->][?:ShoppingItem];
}

"""Clear the shopping list."""
def:pub clear_shopping_list -> dict[str, bool] {
    for item in [root-->][?:ShoppingItem] {
        del item;
    }
    return {"cleared": True};
}

cl def:pub app -> JsxElement {
    has tasks: list = [],
        task_text: str = "",
        meal_text: str = "",
        ingredients: list[ShoppingItem] = [],
        generating: bool = False;

    async can with entry {
        tasks = await get_tasks();
        ingredients = await get_shopping_list();
    }

    async def add_new_task {
        if task_text.strip() {
            task = await add_task(task_text.strip());
            tasks = tasks + [task];
            task_text = "";
        }
    }

    async def toggle(id: str) {
        updated = await toggle_task(id);
        tasks = [updated if jid(t) == id else t for t in tasks];
    }

    async def remove(id: str) {
        await delete_task(id);
        tasks = [t for t in tasks if jid(t) != id];
    }

    async def clear_done {
        await clear_completed();
        tasks = [t for t in tasks if not t.done];
    }

    async def generate_meal_list {
        if meal_text.strip() {
            generating = True;
            ingredients = await generate_list(meal_text.strip());
            generating = False;
        }
    }

    async def clear_list {
        await clear_shopping_list();
        ingredients = [];
        meal_text = "";
    }

    remaining = len([t for t in tasks if not t.done]);
    completed = len(tasks) - remaining;
    total_cost = 0.0;
    for ing in ingredients { total_cost = total_cost + ing.cost; }

    return
        <div class="container">
            <h1>AI Day Planner</h1>
            <div class="two-column">
                <div class="column">
                    <h2>Today's Tasks</h2>
                    <div class="input-row">
                        <input
                            class="input"
                            value={task_text}
                            onChange={lambda e: ChangeEvent { task_text = e.target.value; }}
                            onKeyPress={lambda e: KeyboardEvent {
                                if e.key == "Enter" { add_new_task(); }
                            }}
                            placeholder="What needs to be done today?"
                        />
                        <button class="btn-add" onClick={add_new_task}>Add</button>
                    </div>
                    {[
                        <div key={jid(t)} class="task-item">
                            <input
                                type="checkbox"
                                checked={t.done}
                                onChange={lambda { toggle(jid(t)); }}
                            />
                            <span class={"task-title " + ("task-done" if t.done else "")}>
                                {t.title}
                            </span>
                            {(
                                <span class="category">{t.category}</span>
                            ) if t.category and t.category != "other" else None}
                            <button
                                class="btn-delete"
                                onClick={lambda { remove(jid(t)); }}
                            >
                                X
                            </button>
                        </div> for t in tasks
                    ]}
                    <div class="count-row">
                        <span class="count">{remaining} {("task" if remaining == 1 else "tasks")} remaining</span>
                        {(<button class="btn-clear" onClick={clear_done}>Clear {completed} completed</button>)
                            if completed > 0 else None}
                    </div>
                </div>
                <div class="column">
                    <h2>Meal Shopping List</h2>
                    <div class="input-row">
                        <input
                            class="input"
                            value={meal_text}
                            onChange={lambda e: ChangeEvent { meal_text = e.target.value; }}
                            onKeyPress={lambda e: KeyboardEvent {
                                if e.key == "Enter" { generate_meal_list(); }
                            }}
                            placeholder="Describe a meal, e.g. 'chicken stir fry for 4'"
                        />
                        <button
                            class="btn-generate"
                            onClick={generate_meal_list}
                            disabled={generating}
                        >
                            {("Generating..." if generating else "Generate")}
                        </button>
                    </div>
                    {(
                        <div class="generating-msg">Generating with AI...</div>
                    ) if generating else None}
                    {[
                        <div key={ing.name} class="ingredient-item">
                            <div class="ing-info">
                                <span class="ing-name">{ing.name}</span>
                                <span class="ing-qty">
                                    {ing.quantity} {ing.unit}
                                </span>
                            </div>
                            <div class="ing-meta">
                                {(
                                    <span class="carb-badge">Carbs</span>
                                ) if ing.carby else None}
                                <span class="ing-cost">${f"{ing.cost:.2f}"}</span>
                            </div>
                        </div> for ing in ingredients
                    ]}
                    {(
                        <div class="shopping-footer">
                            <span class="total">Total: ${f"{total_cost:.2f}"}</span>
                            <button class="btn-clear" onClick={clear_list}>Clear</button>
                        </div>
                    ) if len(ingredients) > 0 else None}
                </div>
            </div>
        </div>;
}
