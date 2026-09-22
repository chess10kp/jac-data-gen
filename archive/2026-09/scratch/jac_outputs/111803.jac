"""Option value converter for a continuation align style string."""
def _ContinuationAlignStyleStringConverter(s: Any) -> object {
    accepted_styles = ('SPACE', 'FIXED', 'VALIGN-RIGHT');
    if s {
        r = s.strip('"\'').replace('_', '-').upper();
        if (r not in accepted_styles) {
            raise ValueError(('unknown continuation align style: %r' % (s, )));
        }
    } else {
        r = accepted_styles[0];
    }
    return r;
}