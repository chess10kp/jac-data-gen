"""Backend-offline card — ports ui/components/offline.tsx.

Purely presentational: a dashed status card shown by AppShell when the online
probe fails. AppShell owns the retry-every-3s loop and swaps this out the moment
the backend answers again; onRetry (optional) fires an immediate re-probe."""

import from .shared.Button { Button }

def:pub Offline(onRetry: Callable[([], None)] = None) -> JsxElement {
    return <div className="flex h-screen items-center justify-center">
        <div className="rounded-lg border border-dashed border-input bg-card p-8 text-center">
            <div className="micro-label mb-3">JAC.STUDIO · STATUS</div>
            <p className="text-lg text-foreground">backend offline</p>
            <p className="mt-2 font-mono text-xs text-muted-foreground">
                start it with: <span className="text-foreground/80">jac serve main.jac</span>
            </p>
            <p className="mt-4 font-mono text-[10px] text-muted-foreground/70">retrying every 3s…</p>
            {onRetry and <div className="mt-4">
                <Button variant="outline" onClick={lambda e: MouseEvent { onRetry(); }}>RETRY NOW</Button>
            </div>}
        </div>
    </div>;
}
