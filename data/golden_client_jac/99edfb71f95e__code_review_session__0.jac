cl {
    import from "./Button.tsx" { Button }

    def:pub app() -> JsxElement {
        has clicks: int = 0;

        return <Button
            label={f"Clicked {clicks} times"}
            onClick={lambda -> None { clicks = clicks + 1; }}
        />;
    }
}
