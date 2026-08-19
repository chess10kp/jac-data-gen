# A complete full-stack AI app in one file
node Todo {
    has title: str, category: str = "other", done: bool = False;
}

enum Category { WORK, PERSONAL, SHOPPING, HEALTH, OTHER }

def categorize(title: str) -> Category by llm();

def:pub add_todo(title: str) -> Todo {
    result = categorize(title);
    todo = Todo(title=title, category=result.name.lower());
    root ++> todo;
    return todo;
}

def:pub get_todos() -> list[Todo] {
    return [root -->][?:Todo];
}

cl {
    def:pub app() -> JsxElement {
        has todos: list[Todo] = [];
        has text: str = "";
        async can with entry { todos = await get_todos(); }
        async def add() -> None {
            if text.strip() {
                new_todo = await add_todo(text.strip());
                todos = todos + [new_todo];
                text = "";
            }
        }
        return <div>
            <input value={text}
                onChange={lambda e: any -> None { text = e.target.value as str; }}
                placeholder="Add a todo..." />
            <button onClick={add}>Add</button>
            {[<p key={jid(t)}>{t.title} ({t.category})</p> for t in todos]}
        </div>;
    }
}
