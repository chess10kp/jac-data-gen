cl {
    def:pub UserGreeting(isLoggedIn: bool) -> JsxElement {
        if isLoggedIn {
            return <h1>Welcome back!</h1>;
        }
        return <div>
            <h1>Please sign in</h1>
            <a href="/login">Go to login</a>
        </div>;
    }
}
