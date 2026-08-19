cl import from "@jac/runtime" { Link }

cl {
    def:pub NavExample() -> JsxElement {
        return <div>
            <Link to="/about">About</Link>
            <a href="https://example.com" target="_blank" rel="noopener noreferrer">External Site</a>
        </div>;
    }
}
