def:pub Counter() -> JsxElement {
    has count: int = 0;
    has label: str = "";

    async can with entry {
        count = 0;                               # mount effect - runs once
    }

    def handle_click(e: MouseEvent) {
        count = count + 1;
    }

    def handle_input(e: ChangeEvent) {
        label = e.target.value;                  # .target.value is typed via ChangeEvent
    }

    return <section className="p-4">
        <input value={label} onChange={handle_input} />
        <h1 className="text-xl">
            {"Clicks: " + str(count) if count > 0 else "Start clicking!"}
        </h1>
        <button onClick={handle_click}>+</button>
    </section>;
}
