"""
    Requries the data to be in the format

     >>> (*elem, target, [*keys])

    The output will be a tuple of {keys: elem}
    and target
    """
def pack(batch: Any) -> object {
    inp = batch[:-2];
    target = batch[-2];
    keys = batch[-1];
    inp = {k: v for (k, v) in zip(keys, inp)};
    return (inp, target);
}