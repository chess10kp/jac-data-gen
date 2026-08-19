cl import from "@jac/runtime" { useNavigate, Navigate, useParams }

cl {
    def:pub UserGate() -> JsxElement {
        params = useParams();
        navigate = useNavigate();
        userId = params["id"];

        if not userId {
            return <Navigate to="/users" />;
        }

        return <button type="button" onClick={lambda -> None { navigate(f"/users/{userId}/edit"); }}>
            Edit user {userId}
        </button>;
    }
}
