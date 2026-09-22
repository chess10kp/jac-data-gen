def check_port(port):
    """ Check if a port is valid. Return an error message indicating what is invalid if something isn't valid. """
    if isinstance(port, int):
        if port not in range(0, 65535):
            return 'Source port must in range from 0 to 65535'
    else:
        return 'Source port must be an integer'
    return None

assert check_port(3000) == None
assert check_port(1023) == None
assert check_port(8080.0) == 'Source port must be an integer'
assert check_port('def') == 'Source port must be an integer'
assert check_port(-123) == 'Source port must in range from 0 to 65535'
assert check_port(443) == None
assert check_port({'a': 1}) == 'Source port must be an integer'
assert check_port(123) == None
assert check_port('1') == 'Source port must be an integer'
assert check_port(42.5) == 'Source port must be an integer'
assert check_port(123.4) == 'Source port must be an integer'
assert check_port(-1) == 'Source port must in range from 0 to 65535'
assert check_port(2.718) == 'Source port must be an integer'
assert check_port(65536) == 'Source port must in range from 0 to 65535'
assert check_port(1024) == None
assert check_port('asdf') == 'Source port must be an integer'
assert check_port('3000') == 'Source port must be an integer'
assert check_port(49151) == None
assert check_port(-65536) == 'Source port must in range from 0 to 65535'
assert check_port(30000) == None
assert check_port(1 + 2j) == 'Source port must be an integer'
assert check_port(-10) == 'Source port must in range from 0 to 65535'
assert check_port([]) == 'Source port must be an integer'
assert check_port(80) == None
assert check_port('22') == 'Source port must be an integer'
assert check_port('abc') == 'Source port must be an integer'
assert check_port(43210) == None
assert check_port('50000.5') == 'Source port must be an integer'
assert check_port(1.00) == 'Source port must be an integer'
assert check_port(0) == None
assert check_port([1, 2, 3]) == 'Source port must be an integer'
assert check_port({'foo': 'bar'}) == 'Source port must be an integer'
assert check_port(8080) == None
assert check_port(22.0) == 'Source port must be an integer'
assert check_port(25000) == None
assert check_port('12345') == 'Source port must be an integer'
assert check_port([1]) == 'Source port must be an integer'
assert check_port('5') == 'Source port must be an integer'
assert check_port(5) == None
assert check_port([1, 2]) == 'Source port must be an integer'
assert check_port('a') == 'Source port must be an integer'
assert check_port(50000.0) == 'Source port must be an integer'
assert check_port(2.5) == 'Source port must be an integer'
assert check_port('0') == 'Source port must be an integer'
assert check_port(1.25) == 'Source port must be an integer'
assert check_port('port') == 'Source port must be an integer'
assert check_port(1.23) == 'Source port must be an integer'
assert check_port('30000') == 'Source port must be an integer'
assert check_port(['abc']) == 'Source port must be an integer'
assert check_port(('a', 1)) == 'Source port must be an integer'
assert check_port(5.5) == 'Source port must be an integer'
assert check_port(object()) == 'Source port must be an integer'
assert check_port(10000000000) == 'Source port must in range from 0 to 65535'
assert check_port(65534) == None
assert check_port(12345) == None
assert check_port({'abc':1, 'def':2}) == 'Source port must be an integer'
assert check_port(30000.0) == 'Source port must be an integer'
assert check_port({}) == 'Source port must be an integer'
assert check_port('80') == 'Source port must be an integer'
assert check_port('1234') == 'Source port must be an integer'
assert check_port('50000') == 'Source port must be an integer'
assert check_port(1.0000) == 'Source port must be an integer'
assert check_port(5000000000000) == 'Source port must in range from 0 to 65535'
assert check_port(49152) == None
assert check_port(['a']) == 'Source port must be an integer'
assert check_port([5]) == 'Source port must be an integer'
assert check_port(1.000) == 'Source port must be an integer'
assert check_port(1) == None
assert check_port('50000.0') == 'Source port must be an integer'
assert check_port(1.0) == 'Source port must be an integer'
assert check_port('123') == 'Source port must be an integer'
assert check_port(22) == None
assert check_port(42) == None
assert check_port({'abc':1}) == 'Source port must be an integer'
assert check_port('443') == 'Source port must be an integer'
assert check_port(1.1) == 'Source port must be an integer'
assert check_port(lambda x: x) == 'Source port must be an integer'
assert check_port(check_port) == 'Source port must be an integer'
assert check_port(500000) == 'Source port must in range from 0 to 65535'
assert check_port(50000.5) == 'Source port must be an integer'
assert check_port(None) == 'Source port must be an integer'
assert check_port(2**32) == 'Source port must in range from 0 to 65535'
