"""
  Tests if object is a libsbml model
  """
def _isSBMLModel(`obj: object) -> bool {
    cls_stg = str(`type(`obj));
    return "Model" in cls_stg and "lib" in cls_stg;
}