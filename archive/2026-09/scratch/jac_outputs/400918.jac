"""
    Function used to preprocess the input and output for the model.
    The input gets the special [SEP] token and the output gets a space added.
    """
def preprocess(data: Any) -> object {
    return {
        "input": (data['premise'] + '</s>' + data['hypothesis']),
        "output": (str(data['label']) + ' ' + data['explanation_1'])
    };
}