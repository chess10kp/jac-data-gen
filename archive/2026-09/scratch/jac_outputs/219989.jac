import logging;

"""This method is deprecated. It converted unicode string into VTK string, but
  since now VTK assumes that all strings are in UTF-8 and all strings in Slicer are UTF-8, too,
  conversion is no longer necessary.
  The method is only kept for backward compatibility and will be removed in the future.
  """
def toVTKString(text: str) -> str {
    logging.warning("toVTKString is deprecated! Conversion is no longer necessary.");
    return text;
}