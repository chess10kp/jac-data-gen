import from app.components.AppShell { AppShell }

def:pub Layout() -> JsxElement {
    return <div className="min-h-screen">
        <AppShell />
    </div>;
}
