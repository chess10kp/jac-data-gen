
def toast_bg_class(kind: str) -> str {
    if kind == "error" {
        return "bg-red-950/95 border-red-500/40";
    }
    if kind == "success" {
        return "bg-green-950/95 border-green-500/40";
    }
    return "bg-panel-soft/95 border-border";
}

def toast_icon(kind: str) -> str {
    if kind == "error" { return "⚠"; }
    if kind == "success" { return "✓"; }
    return "ℹ";
}

def toast_icon_cls(kind: str) -> str {
    if kind == "error" { return "shrink-0 mt-0.5 text-red-400"; }
    if kind == "success" { return "shrink-0 mt-0.5 text-green-400"; }
    return "shrink-0 mt-0.5 text-accent";
}

def invoke_toast_dismiss(fn: any, id: str) -> None {
    fn.call(None, id);
}

def:pub ToastStack(toasts: list[any] = [], onDismiss: any = None) -> JsxElement {
    items: list[JsxElement] = [];
    for t in toasts {
        tid: str = str(t["id"]);
        msg: str = str(t["msg"]);
        kind: str = str(t["kind"]) if t["kind"] else "error";
        bg: str = toast_bg_class(kind);
        icon: str = toast_icon(kind);
        iconCls: str = toast_icon_cls(kind);
        dismissFn: any = onDismiss;
        capturedId: str = tid;
        items.append(
            <div
                key={tid}
                className={"flex items-start gap-2 rounded-xl border px-3 py-2.5 text-sm text-foreground shadow-xl backdrop-blur " + bg}
            >
                <span className={iconCls}>{icon}</span>
                <span className="flex-1 min-w-0 break-words leading-snug">{msg}</span>
                <button
                    onClick={lambda (e: any) -> None { if dismissFn { invoke_toast_dismiss(dismissFn, capturedId); }}}
                    className="shrink-0 ml-1 mt-0.5 text-muted hover:text-foreground transition-colors leading-none"
                >×</button>
            </div>
        );
    }
    return <div className="fixed top-4 right-4 z-[100] flex flex-col gap-2 w-80 max-w-[90vw]">
        {items}
    </div>;
}
