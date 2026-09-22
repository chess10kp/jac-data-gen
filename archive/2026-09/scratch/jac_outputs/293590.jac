"""
  Removes all items within list of excluded files from list of included files.

  Args:
      include: list containing directories of all files matching --add=GLOB.
      exclude: list containing directories of all files matching --rm=GLOB.

  Returns:
      include: a final list with all files to which the header will be prepended.

  """
def join(`include: Any, exclude: Any) -> object {
    for excludefile in exclude {
        if (excludefile in `include) {
            `include.remove(excludefile);
        }
    }
    return `include;
}