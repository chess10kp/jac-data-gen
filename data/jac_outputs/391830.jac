"""Extract port number from command line argument."""
def extract_port_num(arg: str) -> int {
    port = 0;
    try {
        port = int(arg);
    } except ValueError {
        print("Invalid port number\n");
    }
    return port;
}