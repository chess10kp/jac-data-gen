cl {
    def:pub Form() -> JsxElement {
        has value: str = "";

        def submit() -> None {
            print(f"submitting: {value}");
        }

        return <div>
            <input
                value={value}
                onChange={lambda e: ChangeEvent { value = e.target.value; }}
                onKeyDown={lambda e: KeyboardEvent {
                    if e.key == "Enter" { submit(); }
                }}
            />
            <button onClick={lambda -> None { submit(); }}>
                Submit
            </button>
        </div>;
    }
}
