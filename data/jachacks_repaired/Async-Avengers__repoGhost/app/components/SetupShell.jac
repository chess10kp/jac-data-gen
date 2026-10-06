
def invoke_callback(fn: any, value: any) -> None {
    fn.call(None, value);
}

async def invoke_async_callback(fn: any) -> None {
    await fn.call(None);
}

def setup_option_rows(modelOptions: list[str]) -> list[JsxElement] {
    rows: list[JsxElement] = [];
    for item in modelOptions {
        rows.append(<option key={item} value={item}>{item}</option>);
    }
    if len(rows) == 0 {
        rows.append(<option key="gpt-4o-mini" value="gpt-4o-mini">gpt-4o-mini</option>);
    }
    return rows;
}

def:pub SetupShell(
    apiKey: str = "",
    selectedModel: str = "gpt-4o-mini",
    modelOptions: list[str] = [],
    rememberSettings: bool = True,
    loading: bool = False,
    error: str = "",
    setApiKey: any = None,
    setSelectedModel: any = None,
    setRememberSettings: any = None,
    submitSetup: any = None
) -> JsxElement {
    modelRows: list[JsxElement] = setup_option_rows(modelOptions);
    buttonLabel: str = "Saving..." if loading else "Enter repoGhost";
    errorBanner: JsxElement = <div />;
    if error {
        errorBanner = <div className="rounded-2xl border border-danger/40 bg-danger/10 px-4 py-3 text-sm text-foreground">
            {error}
        </div>;
    }

    async def submit() -> None {
        if submitSetup {
            await invoke_async_callback(submitSetup);
        }
    }

    return <div className="mx-auto flex w-full max-w-[560px] flex-col gap-5 rounded-[2rem] border border-border bg-panel/90 px-7 py-7 shadow-[var(--shadow-glow)] backdrop-blur">
        <div className="space-y-3">
            <div className="inline-flex h-12 w-12 items-center justify-center rounded-2xl border border-border bg-panel-soft text-2xl">
                👻
            </div>
            <div>
                <div className="text-[28px] font-semibold tracking-tight text-foreground">repoGhost</div>
                <div className="mt-2 text-[15px] leading-6 text-muted">
                    Set your OpenAI key and preferred GPT model before entering the widget. Leave the key empty to continue in deterministic mode.
                </div>
            </div>
        </div>

        {errorBanner}

        <div className="space-y-4">
            <div>
                <div className="mb-2 text-sm font-semibold text-foreground">OpenAI API Key</div>
                <input
                    type="password"
                    value={apiKey}
                    onChange={lambda (e: any) -> None { if setApiKey { invoke_callback(setApiKey, e.target.value); } }}
                    placeholder="sk-..."
                    className="w-full rounded-2xl border border-border bg-panel-soft px-4 py-3 text-[15px] text-foreground outline-none placeholder:text-muted focus:border-accent transition-colors"
                />
            </div>

            <div>
                <div className="mb-2 text-sm font-semibold text-foreground">GPT Model</div>
                <select
                    value={selectedModel}
                    onChange={lambda (e: any) -> None { if setSelectedModel { invoke_callback(setSelectedModel, e.target.value); } }}
                    className="w-full rounded-2xl border border-border bg-panel-soft px-4 py-3 text-[15px] text-foreground outline-none focus:border-accent transition-colors"
                >
                    {modelRows}
                </select>
            </div>

            <label className="flex items-center gap-3 rounded-2xl border border-border bg-panel-soft px-4 py-3 text-[15px] text-foreground">
                <input
                    type="checkbox"
                    checked={rememberSettings}
                    onChange={lambda (e: any) -> None { if setRememberSettings { invoke_callback(setRememberSettings, e.target.checked); } }}
                    className="h-4 w-4"
                />
                <span>Remember this API key and model on this device</span>
            </label>
        </div>

        <button
            onClick={submit}
            disabled={loading}
            className="inline-flex items-center justify-center rounded-2xl bg-accent px-5 py-3 text-[15px] font-semibold text-background transition hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-60"
        >
            {buttonLabel}
        </button>
    </div>;
}
