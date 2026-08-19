# main.jac
cl {
    import from "./components/Header.cl.jac" { Header }

    def:pub app() -> JsxElement {
        return <div>
            <Header />
            <main>Content</main>
        </div>;
    }
}
