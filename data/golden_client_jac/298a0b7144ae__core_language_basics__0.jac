"""Single ingredient row -- presentational."""
cl def:pub IngredientItem(ing: ShoppingItem) -> JsxElement {
    return
        <div class="ingredient-item">
            <div class="ing-info">
                <span class="ing-name">{ing.name}</span>
                <span class="ing-qty">{ing.quantity} {ing.unit}</span>
            </div>
            <div class="ing-meta">
                {(<span class="carb-badge">Carbs</span>) if ing.carby else None}
                <span class="ing-cost">${f"{ing.cost:.2f}"}</span>
            </div>
        </div>;
}

"""Shopping list column -- owns ingredient state, fetches on mount."""
cl def:pub ShoppingColumn -> JsxElement {
    has ingredients: list[ShoppingItem] = [],
        meal_text: str = "",
        generating: bool = False;

    async can with entry {
        ingredients = await get_shopping_list();
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

    total_cost = 0.0;
    for ing in ingredients {
        total_cost = total_cost + ing.cost;
    }

    return
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
            {(<div class="generating-msg">Generating with AI...</div>)
                if generating
                else None}
            {[<IngredientItem key={ing.name} ing={ing}/> for ing in ingredients]}
            {(
                <div class="shopping-footer">
                    <span class="total">Total: ${f"{total_cost:.2f}"}</span>
                    <button class="btn-clear" onClick={clear_list}>Clear</button>
                </div>
            ) if len(ingredients) > 0 else None}
        </div>;
}
