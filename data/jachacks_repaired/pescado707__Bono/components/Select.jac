"""Select dropdown component for the Jac client application."""

def:pub Select(value: str = "", onChange: any = None, options: list = [], label: str = "", placeholder: str = "Select...", disabled: bool = False) -> JsxElement {
    select_cls = "px-3 py-2 text-base rounded-md border border-gray-300 outline-none w-full text-gray-900 "
        + ("bg-gray-50 cursor-not-allowed" if disabled else "bg-white cursor-pointer");

    return <div className="flex flex-col gap-1">
        {label and <label className="text-sm font-medium text-gray-700">{label}</label>}
        <select
            value={value}
            onChange={onChange}
            disabled={disabled}
            className={select_cls}
        >
            <option value="" disabled>{placeholder}</option>
            {for opt in options {
                <option value={opt} key={opt}>{opt}</option>
            }}
        </select>
    </div>;
}
