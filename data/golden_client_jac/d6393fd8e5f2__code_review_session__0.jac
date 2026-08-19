# pages/layout.jac
cl import from "@jac/runtime" { Outlet }
cl import from ..components.navigation { Navigation }

cl {
    def:pub layout() -> JsxElement {
        return <>
            <header>
                <Navigation />
            </header>
            <main style={{"maxWidth": "960px", "margin": "0 auto"}}>
                <Outlet />
            </main>
            <footer>Footer content</footer>
        </>;
    }
}
