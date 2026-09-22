"""
Strip the header and footer of a .pem. BEWARE: Won't work with explanatory
strings above the header.
@params pem A string representing the pem
"""
def pem2b64(pem: bytes) -> str {
    text = pem.decode('ascii');
    return '\n'.join(text.strip().split('\n')[1:-1]);
}