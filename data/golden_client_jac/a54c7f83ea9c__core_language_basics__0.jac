cl {
    import "./assets/main.css";  # contains: @import "tailwindcss";

    def:pub app() -> JsxElement {
        return <div className="min-h-screen bg-gray-100 p-8">
            <h1 className="text-3xl font-bold">Hello</h1>
        </div>;
    }
}
