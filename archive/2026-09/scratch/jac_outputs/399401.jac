import re;

"""Recognise stressful subject."""
def is_stressful(subj: str) -> bool {
    return (
        subj.isupper()
        or subj.endswith('!!!')
        or any(
            re.search('+[.!-]*'.join(word), subj.lower())
            for word in ('help', 'asap', 'urgent')
        )
    );
}