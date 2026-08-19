cl {
    def:pub App() -> JsxElement {
        return <div>
            <h1>Hello</h1>
            {#* TODO: replace with a custom Button component *#}
            <button type="button" onClick={lambda -> None { print("clicked"); }}>Click me</button>
        </div>;
    }
}
