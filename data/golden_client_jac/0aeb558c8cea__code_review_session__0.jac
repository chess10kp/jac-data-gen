cl {
    def:pub app() -> JsxElement {
        has clicks: int = 0;
        return <div>
            <Card title="Welcome" description="Hello!">
                <Button onClick={lambda -> None { clicks = clicks + 1; }}>
                    Click Me ({clicks})
                </Button>
            </Card>
        </div>;
    }
}
