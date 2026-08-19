cl {
    def:pub Button() -> JsxElement {
        def handle_click() -> None {
            print("Button clicked!");
        }

        return <button onClick={lambda -> None { handle_click(); }}>
            Click me
        </button>;
    }
}
