cl {
    def:pub Card(title: str, children: any = None) -> JsxElement {
        return <div className="card">
            <div className="card-header">{title}</div>
            <div className="card-body">{children}</div>
        </div>;
    }

    def:pub app() -> JsxElement {
        return <Card title="Welcome">
            <p>This is the card content.</p>
            <button>Action</button>
        </Card>;
    }
}
