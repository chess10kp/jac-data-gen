# pages/users/[id].jac
cl import from "@jac/runtime" { Link, useParams }

cl {
    def:pub page() -> JsxElement {
        params = useParams();
        userId = params["id"];

        users = {
            "1": {"name": "Alice", "role": "Admin"},
            "2": {"name": "Bob", "role": "Developer"}
        };

        user = users.get(userId, None);

        if not user {
            return <div>
                <h1>User Not Found</h1>
                <Link to="/users">Back to Users</Link>
            </div>;
        }

        return <div>
            <Link to="/users">Back</Link>
            <h1>User: {user["name"]}</h1>
            <p>Role: {user["role"]}</p>
        </div>;
    }
}
