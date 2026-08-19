# Server codespace (default)
node Todo {
    has title: str, done: bool = False;
}

def:pub add_todo(title: str) -> dict {
    todo = root ++> Todo(title=title);
    return {"id": jid(todo[0]), "title": todo[0].title};
}

cl {
    def:pub app -> JsxElement {
        has items: list = [];

        async def add -> None {
            todo = await add_todo("New");
            items = items + [todo];
        }

        return <div>
            <button onClick={lambda -> None { add(); }}>
                Add
            </button>
        </div>;
    }
}
