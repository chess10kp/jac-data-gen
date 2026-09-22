"""Sort string txt by each word's last character."""
def sort_by_last(txt: str) -> str {
    " ".join(sorted(txt.split(' '), key=lambda (x: str) { x[-1].lower(); }))
}