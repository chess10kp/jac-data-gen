"""
    Instruct ll2ctypes that this llhelper can raise RPython exceptions, which
    should be propagated.
    """
def llhelper_can_raise(func: Callable[..., object]) -> Callable[..., object] {
    setattr(func, "_llhelper_can_raise_", True);
    return func;
}