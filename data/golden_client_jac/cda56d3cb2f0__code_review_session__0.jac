cl import from "@jac/runtime" { jacLogout, jacIsLoggedIn, useNavigate }

cl {
    def:pub NavBar() -> JsxElement {
        isLoggedIn = jacIsLoggedIn();
        navigate = useNavigate();

        def handleLogout() -> None {
            jacLogout();
            navigate("/login");
        }

        return <nav>
            {(<button onClick={lambda -> None { handleLogout(); }}>Logout</button>) if isLoggedIn else (<a href="/login">Login</a>)}
        </nav>;
    }
}
