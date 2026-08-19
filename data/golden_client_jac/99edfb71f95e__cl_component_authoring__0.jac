cl {
    import from "./Button.tsx" { Button }

    def:pub app() -> JsxElement {
        return <Button
            label="Click me"
            onClick={lambda -> None { print("Clicked!"); }}
        />;
    }
}
