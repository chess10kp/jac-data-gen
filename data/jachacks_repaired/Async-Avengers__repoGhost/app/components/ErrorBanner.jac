def:pub ErrorBanner(message: str = "Something went wrong.") -> JsxElement {
    return <div className="rounded-2xl border border-danger/40 bg-danger/10 px-4 py-3 text-sm text-red-100 shadow-[var(--shadow-panel)]">
        <div className="font-semibold">repoGhost error</div>
        <div className="mt-1 text-red-100/90">{message}</div>
    </div>;
}
