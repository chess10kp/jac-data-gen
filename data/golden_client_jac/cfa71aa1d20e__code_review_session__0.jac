# This is backend code (runs on server)
walker:pub api_endpoint {
    can visit with Root entry { report {}; }
}

# This is frontend code (runs in browser)
cl {
    def:pub MyComponent() -> JsxElement {
        return <div>I run in the browser</div>;
    }
}
