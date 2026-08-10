"""Return the path to BAI file in the same directory as BAM file."""
def bai_path(bamfilepath: str) -> str {
    return f"{bamfilepath}.bai";
}