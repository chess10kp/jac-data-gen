"""Check whether a file is an iPython Notebook."""
def file_is_ipython_notebook(path: str) -> bool {
    return path.lower().endswith(".ipynb");
}