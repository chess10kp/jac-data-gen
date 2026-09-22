"""Add full stops at the end of the utterances."""
def add_stop(utt: str) -> str {
    if utt[-1] not in '.,!:;?' {
        utt = utt + ' .';
    }
    return utt;
}