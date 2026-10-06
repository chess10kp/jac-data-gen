def:pub Input(
    id: str = "",
    name: str = "",
    className: str = "",
    type: str = "text",
    value: str = "",
    placeholder: str = "",
    autoComplete: str = "",
    disabled: bool = False,
    onChange: any = None,
) -> JsxElement {
    return <input
        id={id}
        name={name}
        className={"ui-input " + className}
        type={type}
        value={value}
        placeholder={placeholder}
        autoComplete={autoComplete}
        disabled={disabled}
        onChange={onChange}
    />;
}

def:pub Label(htmlFor: str = "", children: JsxElement = None) -> JsxElement {
    return <label htmlFor={htmlFor} className="ui-label">
        {children}
    </label>;
}
