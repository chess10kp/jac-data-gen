cl import from "@jac/runtime" { Link }

cl {
    def:pub Header() -> JsxElement {
        return <header>
            <h1>My App</h1>
            <Nav />
        </header>;
    }

    def:pub Nav() -> JsxElement {
        return <nav>
            <Link to="/">Home</Link>
            <Link to="/about">About</Link>
        </nav>;
    }

    def:pub Footer() -> JsxElement {
        return <footer>© 2024</footer>;
    }

    def:pub app() -> JsxElement {
        return <div>
            <Header />
            <main>Content here</main>
            <Footer />
        </div>;
    }
}
