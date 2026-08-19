# Card.cl.jac
def:pub Card(title: str, body: str) -> JsxElement {
    return <article className="card">
        <h2 className="card-title">{title}</h2>
        <p>{body}</p>
    </article>;
}
