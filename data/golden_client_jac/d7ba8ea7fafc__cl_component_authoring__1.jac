cl {
    def:pub Counter() -> JsxElement {
        has count: int = 0;

        def bump {
            count = count + 1;
        }

        return <button onClick={bump}>Count: {count}</button>;
    }
}
