"""Text component for the Jac client application."""

def:pub Text(content: str = "", size: str = "1rem", weight: str = "400", color: str = "#374151") -> JsxElement {
    return <p
        className="m-0 leading-normal"
        style={{"fontSize": size, "fontWeight": weight, "color": color}}
    >
        {content}
    </p>;
}
