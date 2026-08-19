cl import from "@jac/pwa" { usePwaInstall }

cl {
    def:pub CustomInstallUI() -> JsxElement {
        (canInstall, triggerInstall) = usePwaInstall();

        return <div>
            {canInstall and (
                <button onClick={lambda -> None { triggerInstall(); }}>
                    Get the App
                </button>
            )}
        </div>;
    }
}
