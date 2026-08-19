"""_should_skip: binary-extension test extracted into its own predicate."""

import os;

glob _BINARY_EXTS: set = {
    ".png", ".jpg", ".jpeg", ".gif", ".ico", ".webp", ".bmp",
    ".woff", ".woff2", ".ttf", ".otf", ".eot",
    ".wasm", ".so", ".dylib", ".dll", ".a", ".o", ".bin",
    ".zip", ".gz", ".tar", ".pdf", ".mp4", ".mov", ".jbc", ".pyc"
};

def _is_binary(rel: str) -> bool {
    ext = os.path.splitext(rel)[1].lower();
    return ext in _BINARY_EXTS;
}

def _should_skip(rel: str) -> bool {
    if "__pycache__" in rel or os.path.basename(rel).startswith(".") {
        return True;
    }
    return _is_binary(rel);
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
