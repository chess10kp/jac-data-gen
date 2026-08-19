cl {
    def:pub Greeting(name: str) -> JsxElement {
        return <div class="card">
            {if name == "" {
                <p>Hello, stranger</p>
            } else {
                <h1>Hello, {name}</h1>
                <p>Welcome back.</p>
            }}
        </div>;
    }
}
