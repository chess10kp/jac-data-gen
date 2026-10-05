"""Card component for the Jac client application."""

def:pub Card(children: any = None, title: str = "", padding: str = "1.5rem") -> JsxElement {
    return <div
        className="bg-white rounded-xl border border-gray-200 shadow-sm w-full"
        style={{"padding": padding}}
    >
        {title and <h3 className="text-xl font-semibold text-gray-900 mt-0 mb-4">{title}</h3>}
        {children}
    </div>;
}
