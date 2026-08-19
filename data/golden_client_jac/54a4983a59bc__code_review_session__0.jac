cl {
    glob CARD_STYLE: dict = {"color": "blue", "padding": "10px"};

    def:pub StyledComponent() -> JsxElement {
        return <div style={CARD_STYLE}>
            Styled content
        </div>;
    }
}
