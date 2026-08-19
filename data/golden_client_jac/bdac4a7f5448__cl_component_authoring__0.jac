cl {
    def:pub Comment(c: dict) -> JsxElement {
        return <article>
            <h3>{c["author"]}</h3>
            <div class="body">{unsafe_html(c["trusted_html"])}</div>
        </article>;
    }
}
