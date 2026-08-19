cl import from "@jac/runtime" { useParams, Link }

cl {
    def:pub page() -> JsxElement {
        params: any = useParams();
        user_id = params.get("id");
        if not user_id {
            return <div>
                <Link to="/users">Back</Link>
                <p>User not found.</p>
            </div>;
        }
        return <div>
            <Link to="/users">Back</Link>
            <h1>User {user_id}</h1>
        </div>;
    }
}
