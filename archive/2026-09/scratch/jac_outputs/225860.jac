"""Get a file by its filename from the results list."""
def get_file(filename: Any, result: Any) -> object {
    return next(
        (
            f
            for f in result
            if (f['filename'] == filename)
        ),
        None
    );
}