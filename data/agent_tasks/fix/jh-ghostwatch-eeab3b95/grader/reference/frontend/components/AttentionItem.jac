def:pub AttentionItem(item: dict[str, str]) -> JsxElement {
    return
        <div className="gw-right-item">
            <div>
                <strong>
                    {item["title"]}
                </strong>
            </div>
            <span>
                {item["value"]}
            </span>
        </div>;
}
