cl {
    def:pub app() -> JsxElement {
        has count: int = 0;

        return <div style={{"textAlign": "center", "marginTop": "50px"}}>
            <h1>Jac Full-Stack</h1>
            <p>Count: {count}</p>
            <button onClick={lambda { count = count + 1; }}>
                Increment
            </button>
        </div>;
    }
}
