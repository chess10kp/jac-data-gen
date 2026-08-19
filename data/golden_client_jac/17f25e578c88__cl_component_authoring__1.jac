cl {
    def:pub UserGreeting(isLoggedIn: bool) -> JsxElement {
        if isLoggedIn {
            return <h1>Welcome back!</h1>;
        }
        return <h1>Please sign in</h1>;
    }
}
