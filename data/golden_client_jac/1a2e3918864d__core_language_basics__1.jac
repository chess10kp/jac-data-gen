cl {
    def:pub Form() -> JsxElement {
        has value: str = "";

        return <div>
            <input
                value={value}
                onChange={lambda e: ChangeEvent { value = e.target.value; }}
                onKeyPress={lambda e: KeyboardEvent {
                    if e.key == "Enter" { submit(); }
                }}
            />
            <button onClick={lambda -> None { submit(); }}>
                Submit
            </button>
        </div>;
    }
}
