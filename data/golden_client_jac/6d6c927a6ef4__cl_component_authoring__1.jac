cl {
    def:pub Header() -> JsxElement {
        return <header>
            <h1>My App</h1>
            <Nav />
        </header>;
    }

    def:pub Nav() -> JsxElement {
        return <nav>
            <a href="/">Home</a>
            <a href="/about">About</a>
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
