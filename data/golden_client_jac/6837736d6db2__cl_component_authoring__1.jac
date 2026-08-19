cl {
    def:pub Greeting(name: str) -> JsxElement {
        return <h1>Hello, {name}!</h1>;
    }

    def:pub app() -> JsxElement {
        return <div>
            <Greeting name="Alice" />
            <Greeting name="Bob" />
        </div>;
    }
}
