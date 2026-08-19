cl {
    def:pub App() -> JsxElement {
        return <JacClientErrorBoundary fallback={<div className="error">Component failed to load</div>}>
            <ExpensiveWidget />
        </JacClientErrorBoundary>;
    }
}
