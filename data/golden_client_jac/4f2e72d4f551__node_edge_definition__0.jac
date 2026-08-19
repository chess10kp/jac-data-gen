# This single jac program is a fullstack application
node Todo {
    has title: str,
        done: bool;
}

def:pub get_todos -> list {
    root ++> [
        Todo("build startup", False),
        Todo("raise funding", False),
        Todo("change the world", False)
    ];
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
