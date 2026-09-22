def is_port_free(port, host="localhost"):
    """Checks if port is open on host"""
    #based on http://stackoverflow.com/a/35370008/952600
    import socket
    from contextlib import closing

    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock:
        if sock.connect_ex((host, port)) == 0:
            return False
        else:
            return True

assert is_port_free(8103) == True
assert is_port_free(55555) == True
assert is_port_free(8092) == True
assert is_port_free(8093) == True
assert is_port_free(8890) == True
assert is_port_free(8080) == True
assert is_port_free(3000, "127.0.0.1") == True
assert is_port_free(2000) == True
assert is_port_free(80) == True
assert is_port_free(8888) == True
assert is_port_free(23, "localhost") == True
assert is_port_free(8097) == True
assert is_port_free(8000, "localhost") == False
assert is_port_free(1234) == True
assert is_port_free(8083) == True
assert is_port_free(8094) == True
assert is_port_free(65535, "localhost") == True
assert is_port_free(8080, "localhost") == True
assert is_port_free(1234, "localhost") == True
assert is_port_free(999) == True
assert is_port_free(777) == True
assert is_port_free(1337) == True
assert is_port_free(27017) == True
assert is_port_free(8095) == True
assert is_port_free(1337, "localhost") == True
assert is_port_free(1) == True
assert is_port_free(8099) == True
assert is_port_free(8084) == True
assert is_port_free(8102) == True
assert is_port_free(1337, "127.0.0.2") == True
assert is_port_free(8087) == True
assert is_port_free(22) == True
assert is_port_free(8088) == True
assert is_port_free(5000, "127.0.0.1") == True
assert is_port_free(8090) == True
assert is_port_free(8100) == True
assert is_port_free(4040, "localhost") == True
assert is_port_free(12345, "localhost") == True
assert is_port_free(22, "localhost") == True
assert is_port_free(30000) == True
assert is_port_free(8089) == True
assert is_port_free(5000) == True
assert is_port_free(1000) == True
assert is_port_free(443) == True
assert is_port_free(12345) == True
assert is_port_free(8081) == True
assert is_port_free(8096) == True
assert is_port_free(1337, "127.0.0.1") == True
assert is_port_free(80, "localhost") == True
assert is_port_free(8085) == True
assert is_port_free(5000, "localhost") == True
assert is_port_free(1234, "127.0.0.1") == True
assert is_port_free(8000) == False
assert is_port_free(8098) == True
assert is_port_free(8086) == True
assert is_port_free(4040) == True
assert is_port_free(1, "localhost") == True
assert is_port_free(8091) == True
assert is_port_free(8101) == True
assert is_port_free(23) == True
assert is_port_free(44444) == True
assert is_port_free(1337, "0.0.0.0") == True
assert is_port_free(65535) == True
assert is_port_free(888) == True
assert is_port_free(8082) == True
