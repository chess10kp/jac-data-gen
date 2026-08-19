cl {
    import from "./Header.cl.jac" { Header }

    def:pub app() -> JsxElement {
        return <>
            <Header title="My App" />
            <main>Content</main>
        </>;
    }
}
