"""Match subdirectory level from absDir against correctRelDir depth."""
def matchSubdirLevel(absDir: str, correctRelDir: str) -> tuple[str, str] {
    num_levels = len(correctRelDir.split('/'));
    abs_dir_components = absDir.split('/');
    matching_subdir = '/'.join(abs_dir_components[1:][-num_levels:]);
    top_dir = '/'.join(abs_dir_components[:-num_levels]);
    return (matching_subdir, top_dir);
}