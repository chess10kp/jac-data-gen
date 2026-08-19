cl {
    def:pub TypedForm() -> JsxElement {
        has text: str = "";
        has checked: bool = False;

        def submit() -> None { print(f"text={text}"); }
        def handleSubmit() -> None { submit(); }

        return <div>
            <input
                value={text}
                onChange={lambda e: ChangeEvent { text = e.target.value; }}
                onKeyDown={lambda e: KeyboardEvent {
                    if e.key == "Enter" and not e.shiftKey { submit(); }
                }}
            />
            <input
                type="checkbox"
                checked={checked}
                onChange={lambda e: ChangeEvent { checked = e.target.checked; }}
            />
            <form onSubmit={lambda e: FormEvent {
                e.preventDefault();
                handleSubmit();
            }}>
                <button type="submit">Submit</button>
            </form>
        </div>;
    }
}
