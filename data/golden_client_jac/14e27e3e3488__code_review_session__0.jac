cl {
    import from "@components/Button" { Button }
    import from "@utils/format" { formatDate }

    def:pub app() -> JsxElement {
        return <div>
            <Button label={formatDate("2026-07-22")} onClick={lambda -> None { }} />
        </div>;
    }
}
