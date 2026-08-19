# main.jac
cl {
    import from .components.Header { Header }

    def:pub app() -> JsxElement {
        return <div>
            <Header />
            <main>Content</main>
        </div>;
    }
}
