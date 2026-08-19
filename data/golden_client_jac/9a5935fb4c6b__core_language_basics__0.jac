cl {
    def:pub TodoApp() -> JsxElement {
        has todos: list = [];

        def add_todo() -> None {
            todos = todos + [{"text": "new item"}];  # New list reference triggers re-render
        }

        def remove_todo(id: int) -> None {
            todos = [t for t in todos if t["id"] != id];  # Filter to new list
        }
    }
}
