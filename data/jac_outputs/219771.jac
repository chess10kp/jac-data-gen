"""Return the aparc+aseg.mgz file"""
def pickaparcannot(files: list[str]) -> list[str] {
    return sorted([s for s in files if 'lh.aparc.annot' in s or 'rh.aparc.annot' in s]);
}