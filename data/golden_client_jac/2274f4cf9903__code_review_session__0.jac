cl {
    def:pub Counter() -> JsxElement {
        has count: int = 0;

        return <div>
            <p>Count: {count}</p>
            <button onClick={lambda -> None { count += 1; }}>
                Increment
            </button>
        </div>;
    }
}
