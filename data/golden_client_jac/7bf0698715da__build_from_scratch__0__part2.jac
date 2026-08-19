import os;

glob _BINARY_EXTS: set = {
    ".png", ".jpg", ".jpeg", ".gif", ".ico", ".webp", ".bmp",
    ".woff", ".woff2", ".ttf", ".otf", ".eot",
    ".wasm", ".so", ".dylib", ".dll", ".a", ".o", ".bin",
    ".zip", ".gz", ".tar", ".pdf", ".mp4", ".mov", ".jbc", ".pyc"
};

def _should_skip(rel: str) -> bool {
    if "__pycache__" in rel or os.path.basename(rel).startswith(".") {
        return True;
    }
    ext = os.path.splitext(rel)[1].lower();
    if ext in _BINARY_EXTS {
        return True;
    }
    return False;
}

with entry {
    cases = [
        "src/main.jac",
        "a/__pycache__/x.pyc",
        "dir/.hidden",
        "logo.PNG",
        "build/app.wasm",
        "readme.md",
        "nested/.gitignore"
    ];
    for c in cases {
        print(c + " -> " + str(_should_skip(c)));
    }
}
