cl import from "@jac/runtime" { Outlet }
cl import from "./components/Sidebar" { Sidebar }

cl {
    # pages/layout.jac -- root layout wrapping all pages
    def:pub layout() -> JsxElement {
        return <>
            <nav>...</nav>
            <main><Outlet /></main>
            <footer>...</footer>
        </>;
    }
}
