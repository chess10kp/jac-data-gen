"""Button component for the Jac client application."""

def:pub Button(label: str, onClick: any, variant: str = "primary", disabled: bool = False) -> JsxElement {
    variant_classes = {
        "primary": "bg-blue-500 text-white",
        "secondary": "bg-gray-500 text-white"
    };

    cls = "px-6 py-3 text-base font-semibold rounded-lg border-none transition-all duration-200 "
        + ("bg-gray-400 text-white cursor-not-allowed" if disabled else variant_classes[variant] + " cursor-pointer");

    return <button
        className={cls}
        onClick={onClick}
        disabled={disabled}
    >
        {label}
    </button>;
}
