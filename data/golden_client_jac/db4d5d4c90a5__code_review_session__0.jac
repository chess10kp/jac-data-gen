cl {
    def:pub Card(title: str, children: any = None) -> JsxElement {
        return <div className="card">
            <h3 className="card-header">{title}</h3>
            <div className="card-body">{children}</div>
        </div>;
    }

    def:pub app() -> JsxElement {
        return <Card title="Welcome">
            <p>This is the card content.</p>
            <button type="button">Action</button>
        </Card>;
    }
}
