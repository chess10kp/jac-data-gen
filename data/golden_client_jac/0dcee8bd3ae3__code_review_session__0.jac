cl import from "@jac/runtime" { Router, Routes, Route, Link }
cl import from "./pages/Home" { Home }
cl import from "./pages/About" { About }

cl {
    def:pub app() -> JsxElement {
        return <Router>
            <nav>
                <Link to="/">Home</Link>
                <Link to="/about">About</Link>
            </nav>

            <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/about" element={<About />} />
            </Routes>
        </Router>;
    }
}
