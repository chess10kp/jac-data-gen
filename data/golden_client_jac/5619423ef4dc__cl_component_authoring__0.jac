cl import from "@jac/runtime" { JacClientErrorBoundary }

cl {
    def:pub app() -> JsxElement {
        return <JacClientErrorBoundary fallback={<div>Oops! Something went wrong.</div>}>
            <MainAppComponents />
        </JacClientErrorBoundary>;
    }
}
