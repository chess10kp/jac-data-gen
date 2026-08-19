# pages/(auth)/layout.jac -- protects all pages in this group
cl import from "@jac/runtime" { AuthGuard, Outlet }

cl {
    def:pub layout() -> JsxElement {
        return <AuthGuard redirect="/login">
            <Outlet />
        </AuthGuard>;
    }
}
