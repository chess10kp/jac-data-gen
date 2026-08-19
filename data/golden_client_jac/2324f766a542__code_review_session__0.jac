cl {
    def:pub ItemList(items: list[str]) -> JsxElement {
        return <>
            {if len(items) == 0 {
                <p className="empty">Nothing here.</p>
                skip;
            }}
            <h2>Items</h2>
            <ul>
                {for (i, item) in enumerate(items) {
                    <li key={i}>{item}</li>
                }}
            </ul>
        </>;
    }
}
