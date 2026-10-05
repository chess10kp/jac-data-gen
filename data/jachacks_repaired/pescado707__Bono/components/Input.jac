"""Input component for the Jac client application."""

def:pub Input(value: str = "", onChange: any = None, placeholder: str = "", label: str = "", type_: str = "text", disabled: bool = False) -> JsxElement {
    input_cls = "px-3 py-2 text-base rounded-md border border-gray-300 outline-none w-full text-gray-900 "
        + ("bg-gray-50 cursor-not-allowed" if disabled else "bg-white cursor-text");

    return <div className="flex flex-col gap-1">
        {label and <label className="text-sm font-medium text-gray-700">{label}</label>}
        <input
            type={type_}
            value={value}
            onChange={onChange}
            placeholder={placeholder}
            disabled={disabled}
            className={input_cls}
        />
    </div>;
}
