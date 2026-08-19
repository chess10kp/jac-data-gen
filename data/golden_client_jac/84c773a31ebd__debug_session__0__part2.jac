cl import from "@jac/runtime" { AuthGuard, Outlet }

# pages/(auth)/layout.jac - Protects all routes in (auth) group
cl {
    def:pub layout() -> JsxElement {
        return <AuthGuard redirect="/login">
            <Outlet />
        </AuthGuard>;
    }
}
