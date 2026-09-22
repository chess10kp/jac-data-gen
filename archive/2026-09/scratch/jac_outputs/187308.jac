"""Returns h_t transparently regardless of RNN type."""
def get_rnn_hidden_state[T](h: T | tuple[T, ...]) -> T {
    return h if not isinstance(h, tuple) else h[0];
}