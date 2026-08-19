cl {
    def:pub Counter() -> JsxElement {
        has count: int = 0;

        return <button onClick={lambda -> None { count = count + 1; }}>
            {count}
        </button>;
    }
}
