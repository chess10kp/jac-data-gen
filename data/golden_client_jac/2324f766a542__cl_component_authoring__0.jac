cl {
    def:pub ItemList(items: list[str]) -> JsxElement {
        return <>
            {if len(items) == 0 {
                <p class="empty">Nothing here.</p>
                skip;
            }}
            <h2>Items</h2>
            {for (i, item) in enumerate(items) {
                <li key={i}>{item}</li>
            }}
        </>;
    }
}
