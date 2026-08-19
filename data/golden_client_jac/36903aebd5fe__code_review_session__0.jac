cl import from "@jac/runtime" { JacClientErrorBoundary }

cl {
    def:pub App() -> JsxElement {
        return <JacClientErrorBoundary fallback={<div>App error</div>}>
            <Header />
            <JacClientErrorBoundary fallback={
                <div>
                    <p>Content error</p>
                    <button onClick={lambda -> None { location.reload(); }}>Retry</button>
                </div>
            }>
                <MainContent />
            </JacClientErrorBoundary>
            <Footer />
        </JacClientErrorBoundary>;
    }
}
