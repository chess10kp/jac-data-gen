cl import from "@jac/runtime" { JacClientErrorBoundary }

cl {
    def:pub App() -> JsxElement {
        return <JacClientErrorBoundary
            fallback={<div className="error">Component failed to load</div>}
            onError={lambda err: any { print(f"widget error: {err}"); }}>
            <ExpensiveWidget />
        </JacClientErrorBoundary>;
    }
}
