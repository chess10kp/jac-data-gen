"""Wait until each connection can be established or the timeout is reached."""
def wait_until_ready(connections_to_test: list[tuple[str, int]], timeout: float = 5) -> bool {
    import socket;
    import time;
    print("Starting connectivity test...");
    print(
        "Given TCP endpoints:",
        " ".join("{}:{}".format(*host_port) for host_port in connections_to_test)
    );
    for conn_tuple in connections_to_test {
        print("Trying to connect to {}:{}...".format(*conn_tuple), end='');
        old_time = time.time();
        while time.time() - old_time < timeout {
            try {
                socket.setdefaulttimeout(timeout);
                socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect(conn_tuple);
            } except ConnectionRefusedError {
                ;
            } else {
                print(" SUCCESS");
                break;
            }
        } else {
            print(" FAIL");
            break;
        }
    } else {
        return True;
    }
    return False;
}