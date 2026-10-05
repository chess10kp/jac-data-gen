"""Badge component for the Jac client application."""

def:pub Badge(label: str = "", variant: str = "default") -> JsxElement {
    variant_classes = {
        "default": "bg-gray-100 text-gray-700",
        "success": "bg-green-100 text-emerald-900",
        "warning": "bg-amber-100 text-amber-800",
        "error": "bg-red-100 text-red-900",
        "info": "bg-blue-100 text-blue-800"
    };

    cls = "inline-block px-3 py-1 text-xs font-semibold rounded-full leading-normal " + variant_classes[variant];

    return <span className={cls}>
        {label}
    </span>;
}
