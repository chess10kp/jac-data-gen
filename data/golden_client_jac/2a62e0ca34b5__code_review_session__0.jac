cl {
    import from lodash { sortBy }

    def:pub app() -> JsxElement {
        items = sortBy(["c", "a", "b"]);
        return <ul>{[<li key={i}>{i}</li> for i in items]}</ul>;
    }
}
