"""Return whether a file is a Jupyter notebook file."""
def is_ipynb_file(file_name: str) -> bool {
    return file_name.endswith(".ipynb");
}