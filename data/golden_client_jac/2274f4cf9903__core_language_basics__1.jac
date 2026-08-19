cl {
    def:pub Counter() -> JsxElement {
        has count: int = 0;  # Reactive state

        return <div>
            <p>Count: {count}</p>
            <button onClick={lambda -> None { count = count + 1; }}>
                Increment
            </button>
        </div>;
    }
}
