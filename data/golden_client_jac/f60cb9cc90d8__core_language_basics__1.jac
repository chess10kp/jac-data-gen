cl import from "@jac/runtime" { Outlet }

cl {
    def:pub layout() -> JsxElement {
        return <div>
            <nav>...</nav>
            <Outlet />
        </div>;
    }
}
