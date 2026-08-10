"""Encode an object into RPC-safe form."""
def rpc_encode(`obj: object) -> object {
    try {
        enc = getattr(`obj, 'rpc_encode');
        return enc();
    } except AttributeError {
        return `obj;
    }
}