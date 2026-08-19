cl import from "@jac/runtime" { useParams }

cl {
    def:pub UserProfile() -> JsxElement {
        params: any = useParams();
        raw_id: any = params.get("id");
        if not raw_id {
            return <div>Invalid user.</div>;
        }
        user_id = int(raw_id);
        return <div>User: {user_id}</div>;
    }

    # Route: /user/:id
}
