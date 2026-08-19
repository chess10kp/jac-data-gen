cl {
    def:pub Card(title: str, description: str = "", children: any = None) -> JsxElement {
        return <div className="card">
            <h2>{title}</h2>
            <p>{description}</p>
            {children}
        </div>;
    }

    def:pub app() -> JsxElement {
        return <Card title="Welcome" description="Hello!">
            <p>This is the card content.</p>
        </Card>;
    }
}
