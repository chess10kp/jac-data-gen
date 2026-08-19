"""Chat composer — ports ui/components/composer.tsx.

Single rounded container holding an auto-growing transparent textarea + a ghost
SEND button, with a row of prompt-category chips above it. The chip label is the
lowercase category id (matches the reference)."""

import from ..shared.Button { Button }

def _rows(value: str) -> int {
    lines = len(value.split(String.fromCharCode(10)));
    n = lines;
    if n < 1 { n = 1; }
    if n > 8 { n = 8; }
    return n;
}

def:pub Composer(
    value: str,
    busy: bool,
    categories: list,
    onSet: Callable[([str], None)],
    onSend: Callable[([str], None)],
    onStop: Callable[([], None)],
    onChip: Callable[([str], None)]
) -> JsxElement {
    return <div className="px-6 pb-4">
        <div className="mb-2 flex flex-wrap gap-1.5">
            {for cat in categories {
                <button
                    key={str(cat["id"])}
                    onClick={lambda e: MouseEvent { onChip(str(cat["id"])); }}
                    className="rounded-full border border-dashed border-ring px-2.5 py-0.5 font-mono text-[9px] text-muted-foreground hover:border-muted-foreground hover:text-foreground"
                >{str(cat["id"])}</button>
            }}
        </div>
        <div className="flex items-end gap-2 rounded-xl border border-input bg-popover p-2 focus-within:border-ring">
            <textarea
                value={value}
                onChange={lambda e: ChangeEvent { onSet(str(e.target.value)); }}
                onKeyDown={lambda e: KeyboardEvent {
                    if e.key == "Enter" and not e.shiftKey {
                        e.preventDefault();
                        onSend(value);
                    }
                }}
                rows={_rows(value)}
                placeholder="Ask the model…  (Enter to send, Shift+Enter for newline)"
                className="max-h-48 flex-1 resize-none bg-transparent px-2 py-1 text-sm text-foreground outline-none placeholder:text-muted-foreground/70"
            />
            <Button
                variant="solid"
                onClick={lambda e: MouseEvent { if busy { onStop(); } else { onSend(value); } }}
                disabled={(not busy) and not value.strip()}
            >
                {"■ STOP" if busy else "⏎ SEND"}
            </Button>
        </div>
    </div>;
}
