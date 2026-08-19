cl {
    import from "../lib/utils" { cn }

    def:pub StylingExamples(condition: bool, hasError: bool, isSuccess: bool) -> JsxElement {
        className = cn(
            "base-class",
            condition and "active",
            {"error": hasError, "success": isSuccess}
        );

        return <div>
            <div className="p-4 bg-blue-500 text-white">Tailwind</div>
            <div className={className}>Dynamic</div>
        </div>;
    }
}
