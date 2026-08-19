cl {
    import from "./components/Button" { Button }

    def:pub app() -> JsxElement {
        return <Button label="Click" onClick={lambda -> None { }} />;
    }
}
