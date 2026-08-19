# pages/(protected)/layout.jac
cl import from "@jac/runtime" { AuthGuard, Outlet }

cl {
    def:pub layout() -> JsxElement {
        return <AuthGuard redirect="/login" fallback={<div>Checking access...</div>}>
            <Outlet />
        </AuthGuard>;
    }
}
