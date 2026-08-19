import from pygments.util { shebang_matches }

def analyse_text(text: str) -> bool;

impl analyse_text {
    return shebang_matches(text, r"pythonw?(3(\.\d)?)?") or "import " in text[:1000];
}
