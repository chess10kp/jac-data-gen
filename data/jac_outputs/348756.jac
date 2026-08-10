"""Helper function to filter tag lists for starting with xmlns:ax."""
def _startswithax(item: str) -> bool {
    return item.startswith('xmlns:ax');
}