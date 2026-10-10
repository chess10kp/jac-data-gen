"""Recipe box - client UI."""

import from endpoints { add_recipe, list_recipes, recipes_with }

def:pub app -> JsxElement {
    has recipes: list[dict[str, any]] = [],
        title: str = "",
        ingredients: str = "",
        query: str = "";

    can with entry {
        loadAll();
    }

    async def loadAll -> None;
    async def addRecipe(e: FormEvent) -> None;
    async def search(e: FormEvent) -> None;

    <div style={{"maxWidth": "640px", "margin": "2rem auto", "fontFamily": "system-ui, sans-serif"}}>
        <h1>Recipe Box</h1>
        <form onSubmit={addRecipe} style={{"display": "flex", "gap": "0.5rem", "marginBottom": "1rem"}}>
            <input
                type="text"
                value={title}
                onChange={lambda (e: ChangeEvent) { title = e.target.value; }}
                placeholder="Recipe title"
            />
            <input
                type="text"
                value={ingredients}
                onChange={lambda (e: ChangeEvent) { ingredients = e.target.value; }}
                placeholder="ingredients, comma, separated"
            />
            <button type="submit">Add</button>
        </form>
        <form onSubmit={search} style={{"display": "flex", "gap": "0.5rem", "marginBottom": "1rem"}}>
            <input
                type="text"
                value={query}
                onChange={lambda (e: ChangeEvent) { query = e.target.value; }}
                placeholder="Find by ingredient"
            />
            <button type="submit">Search</button>
        </form>
        <ul id="recipes">
            {[
                <li key={r["id"]}>
                    <strong>{r["title"]}</strong> - {", ".join(r["ingredients"])} ({r["rating"]} stars)
                </li>
                for r in recipes
            ]}
        </ul>
    </div>
}
