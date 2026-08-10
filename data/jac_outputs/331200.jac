"""
  Reads the `term_browser` field from the given YAML document, validates that it is a supported
  term browser, and returns a corresponding Apache redirect statement.
  """
def translate_terms(yamldoc: dict[str, str], idspace: str) -> str | None {
    if 'term_browser' in yamldoc and yamldoc['term_browser'].strip().lower() == 'ontobee' {
        replacement = (
            'http://www.ontobee.org/browser/rdf.php?'
            'o=%s&iri=http://purl.obolibrary.org/obo/%s_$1'
            % (idspace, idspace)
        );
        return 'RedirectMatch seeother "^/obo/%s_(\\d+)$" "%s"' % (idspace, replacement);
    }
}