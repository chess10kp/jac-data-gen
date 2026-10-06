import from "@jac/runtime" { Navigate }


def:pub page() -> JsxElement {
    return <Navigate to="/start" replace={True}/>;
}
