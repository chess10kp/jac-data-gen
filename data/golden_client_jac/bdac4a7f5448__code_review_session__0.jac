cl {
    def:pub Comment(c: dict[str, any]) -> JsxElement {
        return <article>
            <h3>{c["author"]}</h3>
            <div class="body">
                {(unsafe_html(c["trusted_html"]) if c.get("is_sanitized") else c.get("body", ""))}
            </div>
        </article>;
    }
}
