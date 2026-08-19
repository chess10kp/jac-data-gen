# pages/users/[id].jac
cl import from "@jac/runtime" { useParams }

cl {
    def:pub page() -> JsxElement {
        params = useParams();
        userId = params["id"];

        return <div>
            <h1>User Profile</h1>
            <p>Viewing user: {userId}</p>
        </div>;
    }
}
