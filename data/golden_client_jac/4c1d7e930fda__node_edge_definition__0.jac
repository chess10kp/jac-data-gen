# main.jac - everything in one file

# Backend
node User { has name: str = ""; }
walker get_user {
    can visit with Root entry { report {}; }
}

# Frontend
cl {
    def:pub app() -> JsxElement {
        return <div>App</div>;
    }
}
