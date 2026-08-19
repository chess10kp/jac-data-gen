# Backend code (nodes, walkers)
node Todo {
    has title: str;
    has done: bool = False;
}

walker:pub get_todos {
    can fetch with Root entry {
        report [-->][?:Todo];
    }
}

# Frontend code (client section)
cl {
    def:pub app() -> JsxElement {
        has message: str = "Hello from Jac!";

        return <div>
            <h1>{message}</h1>
        </div>;
    }
}
