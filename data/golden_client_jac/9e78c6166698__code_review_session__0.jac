cl import from "@jac/runtime" { Router, Routes, Route, Link }
cl import from ..components.pages { Home, About }

cl {
    def:pub NotFound() -> JsxElement {
        return <div className="error-page">
            <h1>404</h1>
            <p>Page not found</p>
            <Link to="/">Go Home</Link>
        </div>;
    }

    def:pub app() -> JsxElement {
        return <Router>
            <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/about" element={<About />} />
                <Route path="*" element={<NotFound />} />
            </Routes>
        </Router>;
    }
}
