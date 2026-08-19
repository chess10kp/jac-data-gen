"""CodeBlock — syntax-highlighted code panel with a floating label tab and a
COPY→COPIED button. Ports ui/components/shared/code-block.tsx + lib/highlight.tsx.

The highlighter mirrors highlight.tsx: a single tokenizer regex over comments /
strings / numbers / words, emitting <span> nodes with .tok-kw/.tok-type/.tok-bi/
.tok-str/.tok-num/.tok-com classes (defined in global.css).

# studio: client port uses JS RegExp.matchAll instead of Python `re` — `import re`
# is unresolvable in the Vite/esbuild bundle. RegExp(pat,"g") (no `new`) is valid JS."""

import from .Button { Button }

glob KW: set = {
    "def", "return", "if", "else", "elif", "for", "while", "import", "from",
    "as", "with", "try", "except", "class", "lambda", "pass", "break",
    "continue", "not", "and", "or", "in", "is", "None", "True", "False",
    "walker", "node", "edge", "obj", "can", "has", "visit", "spawn", "report",
    "here", "root", "entry", "exit", "impl", "glob", "test", "yield", "del",
    "global", "assert", "raise", "async", "await"
};
glob TYPE: set = {"int", "float", "str", "list", "dict", "bool", "tuple", "set", "any"};
glob BI: set = {
    "print", "len", "range", "sum", "min", "max", "sorted", "enumerate",
    "zip", "abs", "round", "append", "pop"
};

# Comment | string (double or single quoted) | number | word. Built from three
# raw-string fragments so both quote styles can appear without escaping the delimiter.
glob TOKEN_RE: str =
    r'(#[^\n]*)|("(?:[^"\\]|\\.)*"|'
    + r"'(?:[^'\\]|\\.)*')"
    + r'|(\b\d+(?:\.\d+)?\b)|([A-Za-z_][A-Za-z0-9_]*)';

def _tokClass(word: str) -> str {
    if word in KW {
        return "tok-kw";
    }
    if word in TYPE {
        return "tok-type";
    }
    if word in BI {
        return "tok-bi";
    }
    return "";
}

"""Tokenize *code* into a list of <span> nodes, classed by token kind."""
def _highlight(code: str) -> list {
    nodes: list = [];
    last = 0;
    key = 0;
    rx: any = RegExp;
    arr: any = Array;
    matches: any = arr.from(code.matchAll(rx(TOKEN_RE, "g")));
    for m in matches {
        idx = int(str(m.index));
        if idx > last {
            nodes.append(<span key={str(key)}>{code[last:idx]}</span>);
            key += 1;
        }
        full = str(m[0]);
        com: any = m[1];
        strg: any = m[2];
        num: any = m[3];
        word: any = m[4];
        cls = "";
        if com {
            cls = "tok-com";
        } elif strg {
            cls = "tok-str";
        } elif num {
            cls = "tok-num";
        } elif word {
            cls = _tokClass(str(word));
        }
        if cls {
            nodes.append(<span key={str(key)} className={cls}>{full}</span>);
        } else {
            nodes.append(<span key={str(key)}>{full}</span>);
        }
        key += 1;
        last = idx + len(full);
    }
    if last < len(code) {
        nodes.append(<span key={str(key)}>{code[last:]}</span>);
    }
    return nodes;
}

def:pub CodeBlock(label: str, code: str, lang: str) -> JsxElement {
    has copied: bool = False;

    tab = label if label else ("OUTPUT." + (lang.upper() if lang else "TXT"));

    def _copy() -> None {
        nav: any = navigator;
        nav.clipboard.writeText(code);
        copied = True;
        setTimeout(lambda -> None { copied = False; }, 1200);
    }

    return <div className="relative mt-3 mb-1 rounded-lg border border-border bg-popover">
        <span className="micro-label absolute -top-2 left-3 bg-background px-2">{tab}</span>
        <Button
            onClick={lambda e: MouseEvent { _copy(); }}
            variant="ghost"
            className="absolute right-2 top-2"
        >
            {"COPIED" if copied else "COPY"}
        </Button>
        <pre className="overflow-x-auto p-3 pt-4 font-mono text-xs leading-relaxed text-foreground">
            {_highlight(code)}
        </pre>
    </div>;
}
