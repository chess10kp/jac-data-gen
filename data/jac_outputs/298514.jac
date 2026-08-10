"""Run the adoc command, then show the result in the browser."""
def adoc_with_preview_command(event: dict[str, object] | None = None, verbose: bool = True) -> object {
    c = event and event.get('c');
    if not c {
        return None;
    }
    return getattr(c, 'markupCommands').adoc_command(event, preview=True, verbose=verbose);
}