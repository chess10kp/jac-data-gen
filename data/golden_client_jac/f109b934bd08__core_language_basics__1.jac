cl {
    def:pub TodoApp() -> JsxElement {
        has todos: list = [];
        has input_text: str = "";

        def add_todo() -> None {
            if input_text {
                todos = todos + [{"id": len(todos), "text": input_text}];
                input_text = "";
            }
        }

        def remove_todo(id: int) -> None {
            todos = [t for t in todos if t["id"] != id];
        }

        return <div>
            <input
                value={input_text}
                onChange={lambda e: ChangeEvent { input_text = e.target.value; }}
            />
            <button onClick={lambda -> None { add_todo(); }}>Add</button>

            <ul>
                {[
                    <li key={todo["id"]}>
                        {todo["text"]}
                        <button onClick={lambda -> None { remove_todo(todo["id"]); }}>
                            X
                        </button>
                    </li>
                    for todo in todos
                ]}
            </ul>
        </div>;
    }
}
