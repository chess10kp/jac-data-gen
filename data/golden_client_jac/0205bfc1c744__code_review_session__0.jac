cl {
    def:pub Form() -> JsxElement {
        has name: str = "";
        has items: list = [];

        def add_item() -> None {
            if name {
                items = items + [name];
                name = "";
            }
        }

        return <div>
            <input
                value={name}
                onChange={lambda e: ChangeEvent { name = e.target.value; }}
            />
            <button onClick={lambda -> None { add_item(); }}>Add</button>
            <ul>
                {[<li key={i}>{item}</li> for (i, item) in enumerate(items)]}
            </ul>
        </div>;
    }
}
