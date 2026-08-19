cl {
    def:pub Greeting(props: dict) -> JsxElement {
        return <h1>Hello, {props.name}!</h1>;
    }
}
