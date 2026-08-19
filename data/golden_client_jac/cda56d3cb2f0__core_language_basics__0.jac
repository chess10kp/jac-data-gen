cl import from "@jac/runtime" { jacLogout, jacIsLoggedIn }

cl {
    def:pub NavBar() -> JsxElement {
        isLoggedIn = jacIsLoggedIn();

        def handleLogout() -> None {
            jacLogout();
            # Redirect to login
        }

        return <nav>
            {isLoggedIn and (
                <button onClick={lambda -> None { handleLogout(); }}>Logout</button>
            ) or (
                <a href="/login">Login</a>
            )}
        </nav>;
    }
}
