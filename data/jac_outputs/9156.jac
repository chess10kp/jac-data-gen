"""Return False if any dictionary-learning method was selected.

    Arguments
    ---------
    answers: dict
        Previous questions answers.

    Returns
    -------
    bool
        True if DL verbosity question should be ignored.
    """
def DL_ignore(answers: Any) -> object {
    expected = ['ITKrMM', 'wKSVD', 'BPFA'];
    flag = [(meth in answers['method']) for meth in expected];
    return (True not in flag);
}