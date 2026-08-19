# Card.cl.jac
def:pub Card(title: str, children: any = None) -> JsxElement {
    return <div className="card">
        <h2 className="card-title">{title}</h2>
        <div className="card-content">{children}</div>
    </div>;
}
