cl {
    def:pub Form() -> JsxElement {
        has name: str = "";
        has items: list = [];
        has data: dict = {"key": "value"};

        # Create new references for lists/objects
        def add_item(item: str) -> None {
            items = items + [item];  # Concatenate to new list
        }

        return <div>Form</div>;
    }
}
