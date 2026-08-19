def:pub app() -> JsxElement {
    has width: float = 0.0;

    async can with entry {
        width = window.innerWidth;
        localStorage.setItem("key", "value");
        stored = localStorage.getItem("key");
        print(stored);
    }

    return <div>{width}</div>;
}
