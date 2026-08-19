cl {
    def:pub app() -> JsxElement {
        return <div>
            <Card title="Welcome" description="Hello!">
                <Button onClick={lambda -> None { print("clicked"); }}>
                    Click Me
                </Button>
            </Card>
        </div>;
    }
}
