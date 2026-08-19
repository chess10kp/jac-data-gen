cl {
    def:pub Greeting(props: dict) -> JsxElement {
        return <h1>Hello, {props.name}!</h1>;
    }

    def:pub Counter() -> JsxElement {
        has count: int = 0;
        return <button onClick={lambda { count = count + 1; }}>{count}</button>;
    }
}
