cl {
    import "./assets/main.css";

    def:pub app() -> JsxElement {
        return <main className="min-h-screen bg-gray-100 p-8">
            <h1 className="text-3xl font-bold">Hello</h1>
        </main>;
    }
}
