"""
  <SEMI-PRIVATE> Checks whether the results from the Azure API contain errors or not.
  _check_errors(results)

  results: [str]
    The results from the Azure translation API call

  Returns: bool; True if the API results contain errors.
  """
def _check_errors(results: Any) -> object {
    errors = False;
    for result in results {
        if ('translations' not in result) {
            errors = True;
            break;
        }
    }
    return errors;
}