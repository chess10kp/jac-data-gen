cl {
    def:pub Counter() -> JsxElement {
        has count: int = 0;

        def increment() -> None {
            count = count + 1;
        }

        return <button onClick={increment}>Count: {count}</button>;
    }
}
