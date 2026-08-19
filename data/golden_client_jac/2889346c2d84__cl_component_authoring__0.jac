cl {
    def:pub StyledBox() -> JsxElement {
        return <div style={{
            "backgroundColor": "#f0f0f0",
            "padding": "20px",
            "borderRadius": "8px",
            "boxShadow": "0 2px 4px rgba(0,0,0,0.1)"
        }}>
            Styled content
        </div>;
    }
}
