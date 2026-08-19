cl {
    import from ".components.ui.button" { Button }

    def:pub MyPage() -> JsxElement {
        return <div>
            <Button variant="outline">Click me</Button>
        </div>;
    }
}
