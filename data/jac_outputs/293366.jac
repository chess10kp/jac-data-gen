"""Gets the last `size` bytes of the stacktrace."""
def _stacktrace_end(stacktrace: bytes, size: int) -> bytes {
    stacktrace_length = len(stacktrace);
    if stacktrace_length <= size {
        return stacktrace;
    }
    return stacktrace[:-(stacktrace_length - size)];
}