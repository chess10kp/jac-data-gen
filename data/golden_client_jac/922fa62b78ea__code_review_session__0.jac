cl import from "@jac/runtime" { useNavigate }

cl {
    def:pub NavExample() -> JsxElement {
        navigate = useNavigate();

        return <div>
            <button onClick={lambda -> None { navigate("/home"); }}>
                Go Home
            </button>

            <button onClick={lambda -> None { navigate("/login", {"replace": True}); }}>
                Login (replace)
            </button>

            <button onClick={lambda -> None { navigate(-1); }}>
                Back
            </button>
        </div>;
    }
}
