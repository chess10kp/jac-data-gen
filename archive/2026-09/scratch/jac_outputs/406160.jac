"""
	Split text into lines. Set <code>remove_empty</code> to true to filter out
	empty lines
	@param text: str
	@param remove_empty: bool
	@return list
	"""
def split_by_lines(text: Any, remove_empty: Any = False) -> object {
    lines = text.splitlines();
    return (
        (
            remove_empty
            and [
                line
                for line in lines
                if line.strip()
            ]
        )
        or lines
    );
}