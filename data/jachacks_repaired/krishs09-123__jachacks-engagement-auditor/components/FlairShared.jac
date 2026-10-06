import from "@jac/runtime" { Link as RuntimeLink }
import from .FlairIcons { ArrowRightIcon }

def:pub queryValue(search: str, key: str) -> str {
    clean: str = search;
    if clean.startswith("?") {
        clean = clean[1:];
    }
    parts: list[str] = clean.split("&");
    for part in parts {
        pair: list[str] = part.split("=");
        if len(pair) > 1 and pair[0] == key {
            return pair[1];
        }
    }
    return "";
}

def:pub PageHeader(crumb: str) -> JsxElement {
    return <header className="px-6 py-5 border-b border-border flex items-center justify-between">
        <div className="text-xs uppercase tracking-[0.2em] text-muted-foreground">{crumb}</div>
        <div className="text-xs font-mono text-muted-foreground">flair.</div>
    </header>;
}

def:pub ScorePillar(destination: str, label: str, score: int) -> JsxElement {
    dash: float = (float(score) / 100.0) * 251.2;
    return <RuntimeLink
        to={destination}
        className="paper-card p-6 w-56 flex flex-col items-center text-center hover:border-primary hover:-translate-y-1 transition"
    >
        <div className="relative w-28 h-28">
            <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
                <circle cx="50" cy="50" r="40" fill="none" stroke="var(--surface)" strokeWidth="8" />
                <circle cx="50" cy="50" r="40" fill="none" stroke="var(--primary)" strokeWidth="8" strokeLinecap="round" strokeDasharray={str(dash) + " 251.2"} />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="font-display text-3xl leading-none">{str(score) + "/"}</span>
                <span className="font-display text-3xl leading-none">100</span>
            </div>
        </div>
        <div className="mt-4 text-sm font-medium inline-flex items-center gap-1">
            {label} <ArrowRightIcon className="w-4 h-4" />
        </div>
    </RuntimeLink>;
}

def:pub TagRow(priority: str, element: str) -> JsxElement {
    return <div className="mt-3 flex flex-wrap gap-2">
        <span className="px-2.5 py-1 rounded-md bg-foreground text-background text-[10px] uppercase tracking-widest font-mono">
            {"Priority · " + priority}
        </span>
        <span className="px-2.5 py-1 rounded-md bg-foreground text-background text-[10px] uppercase tracking-widest font-mono">
            {"Element · " + element}
        </span>
    </div>;
}

def:pub Tag(tone: str = "default", children: JsxElement = None) -> JsxElement {
    class_name: str = "px-2 py-0.5 rounded-full text-[10px] font-mono uppercase tracking-widest border ";
    if tone == "primary" {
        class_name = class_name + "bg-primary/15 border-primary/30 text-foreground";
    } else {
        class_name = class_name + "bg-surface border-border text-muted-foreground";
    }
    return <span className={class_name}>{children}</span>;
}
