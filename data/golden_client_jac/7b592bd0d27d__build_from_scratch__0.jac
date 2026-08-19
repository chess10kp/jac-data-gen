import from pygments.util { shebang_matches }

def analyse_text(text: str) -> bool {
    return shebang_matches(text, r"pythonw?(3(\.\d)?)?") or "import " in text;
}
