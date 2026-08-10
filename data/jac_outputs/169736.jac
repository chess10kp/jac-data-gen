"""Decrypts one block of the hidden suffix appended to the user input in the oracle."""
def decrypt_block(n: int, suffix: str, length: int, oracle: Callable[[str], str]) -> str {
    for i in range(16) {
        if len(suffix) == length {
            return suffix;
        }
        inp = 'A' * (15 - i);
        inp_len = len(inp + suffix) + 1;
        inputs = {
            oracle(inp + suffix + chr(j))[:inp_len]: inp + suffix + chr(j)
            for j in range(256)
        };
        suffix += inputs[oracle(inp)[:inp_len]][-1];
    }
    return suffix;
}