cl {
    def:pub SubmitBox() -> JsxElement {
        has value: str = "";

        def handle_submit() -> None {
            if len(value) == 0 {
                return;
            }
            value = "submitted";
        }

        return <button type="button" onClick={lambda -> None { handle_submit(); }}>
            {(value if value else "Submit")}
        </button>;
    }
}
