"""
    Extracts comparison option from filename.
    As example, ``Binarizer-SkipDim1`` means
    options *SkipDim1* is enabled.
    ``(1, 2)`` and ``(2,)`` are considered equal.
    Available options: see :func:`dump_data_and_model`.
    """
def extract_options(name: str) -> dict[str, bool] {
    opts = name.replace("\\", "/").split("/")[-1].split('.')[0].split('-');
    if len(opts) == 1 {
        return {};
    }
    res = {};
    for opt in opts[1:] {
        if opt in (
            "SkipDim1",
            "OneOff",
            "NoProb",
            "NoProbOpp",
            "Dec4",
            "Dec3",
            "Dec2",
            'Svm',
            'Out0',
            'Reshape',
            'SklCol',
            'DF',
            'OneOffArray'
        ) {
            res[opt] = True;
        } else {
            raise NameError("Unable to parse option '{}'".format(opts[1:]));
        }
    }
    return res;
}