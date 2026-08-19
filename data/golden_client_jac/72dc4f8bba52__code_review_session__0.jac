cl import from "@jac/runtime" { Router, Routes, Route }
cl import from ..components.pages { Home, About, Contact, NotFound }

cl {
    def:pub app() -> JsxElement {
        return <Router>
            <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/about" element={<About />} />
                <Route path="/contact" element={<Contact />} />
                <Route path="*" element={<NotFound />} />
            </Routes>
        </Router>;
    }
}
