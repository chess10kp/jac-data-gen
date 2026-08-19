# Card.cl.jac
def:pub Card(title: str) -> JsxElement {
    return <div className="card">
        <h2 className="card-title">{title}</h2>
    </div>;
}
