cl {
    def:pub App() -> JsxElement {
        return <JacClientErrorBoundary fallback={<div>App error</div>}>
            <Header />
            <JacClientErrorBoundary fallback={<div>Content error</div>}>
                <MainContent />
            </JacClientErrorBoundary>
            <Footer />
        </JacClientErrorBoundary>;
    }
}
