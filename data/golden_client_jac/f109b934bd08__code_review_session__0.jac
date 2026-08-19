cl {
    def:pub TodoApp() -> JsxElement {
        has todos: list = [];
        has input_text: str = "";
        has next_id: int = 0;

        def add_todo() -> None {
            if input_text {
                todos = todos + [{"id": next_id, "text": input_text}];
                next_id += 1;
                input_text = "";
            }
        }

        def remove_todo(id: any) -> None {
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
