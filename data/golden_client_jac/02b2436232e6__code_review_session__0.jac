cl {
    def:pub Card(children: any, variant: str = "primary") -> JsxElement {
        return <div className={f"card card-{variant}"}>
            {children}
        </div>;
    }
}
