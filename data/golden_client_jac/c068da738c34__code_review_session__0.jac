cl {
    def:pub TodoList(items: list[dict[str, any]]) -> JsxElement {
        return <ul>
            {[<li key={item["id"]}>{item.get("text", "")}</li> for item in items]}
        </ul>;
    }

    def:pub app() -> JsxElement {
        todos = [
            {"id": 1, "text": "Learn Jac"},
            {"id": 2, "text": "Build app"},
            {"id": 3, "text": "Deploy"}
        ];

        return <TodoList items={todos} />;
    }
}
