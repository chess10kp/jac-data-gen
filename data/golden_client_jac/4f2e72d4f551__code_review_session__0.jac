node Todo {
    has title: str,
        done: bool;
}

# One-time seed: only creates todos if none exist yet.
with entry {
    existing = [root-->][?:Todo];
    if not existing {
        root ++> [
            Todo("build startup", False),
            Todo("raise funding", False),
            Todo("change the world", False)
        ];
    }
}

# Pure read -- no mutation.
def:pub get_todos() -> list {
    return [{"title": t.title, "done": t.done} for t in [root-->][?:Todo]];
}

cl def:pub app() -> JsxElement {
    has items: list = [];

    async can with entry {
        items = await get_todos();
    }

    return
        <div>
            {[<div key={item.title}>
                <input type="checkbox" checked={item.done} />
                {item.title}
            </div> for item in items]}
        </div>;
}
