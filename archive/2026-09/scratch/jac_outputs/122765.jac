"""Adds 1 to every cell in Range"""
def add_one(data: Any) -> object {
    return [[(cell + 1) for cell in row] for row in data];
}