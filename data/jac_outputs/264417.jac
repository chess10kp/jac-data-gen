"""filetoarray"""
def filetoarray(filename: str) -> list[str] {
    try {
        with open(filename, "r") as stream {
            return stream.readlines();
        }
    } except Exception {
        return [];
    }
}