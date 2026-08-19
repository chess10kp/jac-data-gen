cl import from "@jac/runtime" { Router, Routes, Route, Link }

cl {
    def:pub Home() -> JsxElement {
        return <div>
            <h1>Home Page</h1>
            <p>Welcome to our site!</p>
        </div>;
    }

    def:pub About() -> JsxElement {
        return <div>
            <h1>About Us</h1>
            <p>Learn more about our company.</p>
        </div>;
    }

    def:pub Contact() -> JsxElement {
        return <div>
            <h1>Contact</h1>
            <p>Get in touch with us.</p>
        </div>;
    }

    def:pub app() -> JsxElement {
        navLinks = [
            {"to": "/", "label": "Home"},
            {"to": "/about", "label": "About"},
            {"to": "/contact", "label": "Contact"}
        ];
        routes = [
            {"path": "/", "el": <Home />},
            {"path": "/about", "el": <About />},
            {"path": "/contact", "el": <Contact />}
        ];

        return <Router>
            <nav>
                {[<Link key={l["to"]} to={l["to"]}>{l["label"]}</Link> for l in navLinks]}
            </nav>

            <main>
                <Routes>
                    {[<Route key={r["path"]} path={r["path"]} element={r["el"]} /> for r in routes]}
                </Routes>
            </main>
        </Router>;
    }
}
