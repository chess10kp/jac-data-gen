"""
    Return True if backend object is statevector.

    Args:
        backend (BaseBackend): backend instance
    Returns:
        bool: True is statevector
    """
def is_statevector_backend(backend: Any) -> object {
    return backend.name().startswith('statevector') if (backend is not None) else False;
}