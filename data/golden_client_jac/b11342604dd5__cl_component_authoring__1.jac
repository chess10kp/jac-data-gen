def:pub ItemList(items: list[Item]) -> JsxElement {
    return <ul class="items">
        {if len(items) == 0 {
            <p class="empty">Nothing yet.</p>
            skip;                          # skip; ends the slot early
        }}
        <h2>Items</h2>
        {for (i, it) in enumerate(items) {
            <li key={str(i)} class={"done" if it.done else "todo"}>{it.label}</li>
        }}
    </ul>;
}
