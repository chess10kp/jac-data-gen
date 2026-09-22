"""
    Returns a given RPC byte order hash (bytes) to the format expected by
    Bitcoin primitives (blocks, transactions, etc.)
    """
def to_internal_byte_order(rpc_byte_order: Any) -> object {
    return rpc_byte_order[::-1];
}