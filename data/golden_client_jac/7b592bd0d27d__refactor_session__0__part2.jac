"""analyse_text: declaration separated from an impl body (bool-cast keeps the return type)."""

import from pygments.util { shebang_matches }

def analyse_text(text: str) -> bool;

impl analyse_text {
    return bool(shebang_matches(text, r"pythonw?(3(\.\d)?)?")) or "import " in text[:1000];
}

with entry {
    print(analyse_text("import os;"));
    print(analyse_text("#!/usr/bin/env python3\nx = 1;"));
    print(analyse_text("walker foo {}"));
}
