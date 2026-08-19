# main.jac - everything in one file

# Backend
node User { has name: str = ""; }
walker:pub get_user {
    can fetch with Root entry { report [-->][?:User]; }
}

# Frontend
cl {
    def:pub app() -> JsxElement {
        return <div>App</div>;
    }
}
