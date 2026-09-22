"""Check if .txt extension is present"""
def have_txt_extension(l: object) -> int {
    if ".txt" in str(l) {
        return 1;
    }
    return 0;
}