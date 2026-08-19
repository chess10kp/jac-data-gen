cl import from "@jac/runtime" { JacClientErrorBoundary }
cl import from "./components/App" { MainAppComponents }

cl {
    def:pub app() -> JsxElement {
        return <JacClientErrorBoundary fallback={<div>Oops! Something went wrong.</div>}>
            <MainAppComponents />
        </JacClientErrorBoundary>;
    }
}
