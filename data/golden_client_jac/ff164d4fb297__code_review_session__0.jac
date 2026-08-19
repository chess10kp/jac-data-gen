cl {
    def:pub Card(title: str, description: str = "", children: any = None) -> JsxElement {
        return <div className="card">
            <h2>{title}</h2>
            {description and <p>{description}</p>}
            {children}
        </div>;
    }
}
