cl import from "@jac/runtime" { useNavigate, jacIsLoggedIn }

cl {
    def:pub ProtectedRoute(children: any = None) -> JsxElement {
        navigate = useNavigate();
        isAuthenticated = jacIsLoggedIn();

        can with [isAuthenticated] entry {
            if not isAuthenticated {
                navigate("/login", {"replace": True});
            }
        }

        if not isAuthenticated {
            return <div>Redirecting...</div>;
        }

        return <div>{children}</div>;
    }
}
