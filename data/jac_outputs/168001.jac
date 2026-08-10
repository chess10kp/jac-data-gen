"""User defined."""
def predict_callback(data: dict[str, object]) -> bool {
    kwargs = data.get('kwargs') as dict[str, object];
    num = kwargs.get('num');
    if num > 10 {
        return True;
    }
    return False;
}