def:pub Button(
    variant: str = "primary",
    size: str = "md",
    className: str = "",
    type: str = "button",
    disabled: bool = False,
    onClick: any = None,
    children: JsxElement = None,
) -> JsxElement {
    class_name: str = "ui-button ui-button-" + variant + " ui-button-" + size + " " + className;
    return <button
        type={type}
        className={class_name}
        disabled={disabled}
        onClick={onClick}
    >
        {children}
    </button>;
}
