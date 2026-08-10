"""Writes content to the given file."""
def appendToFile(fileName: str, content: str) {
    with open(fileName, "a") as f {
        f.write(content);
    }
}