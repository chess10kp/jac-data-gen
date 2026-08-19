# pages/layout.jac
cl import from "@jac/runtime" { Outlet }
cl import from ..components.navigation { Navigation }

cl {
    def:pub layout() -> JsxElement {
        return <>
            <Navigation />
            <main style={{"maxWidth": "960px", "margin": "0 auto"}}>
                <Outlet />  # Child routes render here
            </main>
            <footer>Footer content</footer>
        </>;
    }
}
