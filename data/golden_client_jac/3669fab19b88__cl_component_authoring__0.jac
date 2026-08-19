"""Field / TextInput / Segmented form primitives. Ports ui/components/shared/field.tsx."""

import from .Chip { Chip }

def:pub Field(label: str, children: any = None) -> JsxElement {
    return <div className="flex flex-col gap-1">
        <span className="micro-label">{label}</span>
        {children}
    </div>;
}

def:pub TextInput(value: str, onSet: Callable[([str], None)], placeholder: str, mono: bool) -> JsxElement {
    return <input
        type="text"
        value={value}
        onChange={lambda e: ChangeEvent { onSet(e.target.value); }}
        placeholder={placeholder}
        className={"w-full rounded-md border border-input bg-popover px-2 py-1 text-sm text-foreground outline-none placeholder:text-muted-foreground/70 focus:border-ring " + (
            "font-mono" if mono else ""
        )}
    />;
}

def:pub Segmented(options: list[str], value: str, onSet: Callable[([str], None)]) -> JsxElement {
    return <div className="flex gap-1">
        {for opt in options {
            <Chip
                key={opt}
                onClick={lambda e: MouseEvent { onSet(opt); }}
                selected={value == opt}
            >
                {opt}
            </Chip>
        }}
    </div>;
}
