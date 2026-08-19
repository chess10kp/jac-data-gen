def timestr_to_int(time_str):
    """ Parse the test time set in the yaml configuration file and convert it to int type """
    # time_int = 0
    if isinstance(time_str, int) or time_str.isdigit():
        time_int = int(time_str)
    elif time_str.endswith("s"):
        time_int = int(time_str.split("s")[0])
    elif time_str.endswith("m"):
        time_int = int(time_str.split("m")[0]) * 60
    elif time_str.endswith("h"):
        time_int = int(time_str.split("h")[0]) * 60 * 60
    else:
        raise Exception("%s not support" % time_str)
    return time_int

assert timestr_to_int("2h") == 7200
assert timestr_to_int("100h") == 360000
assert timestr_to_int("1000000s") == 1000000
assert timestr_to_int(20) == 20
assert timestr_to_int("5m") == 5 * 60
assert timestr_to_int("30h") == 30 * 60 * 60
assert timestr_to_int("100m") == 100 * 60
assert timestr_to_int("1000s") == 1000
assert timestr_to_int("5000m") == 5000 * 60
assert timestr_to_int(2000) == 2000
assert timestr_to_int("10000m") == 600000
assert timestr_to_int("2m") == 2 * 60
assert timestr_to_int("10m") == 600
assert timestr_to_int("30s") == 30
assert timestr_to_int(2) == 2
assert timestr_to_int("5000s") == 5000
assert timestr_to_int("123m") == 60 * 123
assert timestr_to_int(1000) == 1000
assert timestr_to_int("123h") == 60 * 60 * 123
assert timestr_to_int("60m") == 60 * 60
assert timestr_to_int("20m") == 1200
assert timestr_to_int("1s") == 1
assert timestr_to_int(5) == 5
assert timestr_to_int("300m") == 300 * 60
assert timestr_to_int("0m") == 0
assert timestr_to_int("1000h") == 1000 * 60 * 60
assert timestr_to_int("3000h") == 10800000
assert timestr_to_int("400m") == 400 * 60
assert timestr_to_int("300s") == 300
assert timestr_to_int("5") == 5
assert timestr_to_int("10h") == 36000
assert timestr_to_int("5h") == 5 * 60 * 60
assert timestr_to_int("3m") == 3 * 60
assert timestr_to_int(100) == 100
assert timestr_to_int("5m") == 300
assert timestr_to_int("3h") == 3 * 60 * 60
assert timestr_to_int("0h") == 0
assert timestr_to_int("1h") == 3600
assert timestr_to_int("1234m") == 1234 * 60
assert timestr_to_int("10s") == 10
assert timestr_to_int(30) == 30
assert timestr_to_int("2h") == 2 * 60 * 60
assert timestr_to_int(60) == 60
assert timestr_to_int("1m") == 60
assert timestr_to_int("5s") == 5
assert timestr_to_int(300) == 300
assert timestr_to_int(1000000) == 1000000
assert timestr_to_int("12345s") == 12345
assert timestr_to_int("1") == 1
assert timestr_to_int("10m") == 10 * 60
assert timestr_to_int(5000) == 5000
assert timestr_to_int("100m") == 6000
assert timestr_to_int("30h") == 108000
assert timestr_to_int("2000s") == 2000
assert timestr_to_int("3") == 3
assert timestr_to_int("2m") == 120
assert timestr_to_int(10) == 10
assert timestr_to_int("3000") == 3000
assert timestr_to_int("30m") == 1800
assert timestr_to_int("123s") == 123
assert timestr_to_int("3m") == 180
assert timestr_to_int("500h") == 500 * 60 * 60
assert timestr_to_int(2000000) == 2000000
assert timestr_to_int("3h") == 10800
assert timestr_to_int("2000m") == 2000 * 60
assert timestr_to_int("5000h") == 5000 * 60 * 60
assert timestr_to_int("2000m") == 120000
assert timestr_to_int(0) == 0
assert timestr_to_int("2000h") == 2000 * 60 * 60
assert timestr_to_int("0s") == 0
assert timestr_to_int("60s") == 60
assert timestr_to_int("3s") == 3
assert timestr_to_int("1234h") == 1234 * 60 * 60
assert timestr_to_int(12345) == 12345
assert timestr_to_int("10000h") == 36000000
assert timestr_to_int("1000000m") == 1000000 * 60
assert timestr_to_int(10000) == 10000
assert timestr_to_int(1234) == 1234
assert timestr_to_int("100h") == 100 * 60 * 60
assert timestr_to_int("1000m") == 1000 * 60
assert timestr_to_int("1000") == 1000
assert timestr_to_int(123) == 123
assert timestr_to_int("1h") == 60 * 60
assert timestr_to_int("60h") == 60 * 60 * 60
assert timestr_to_int(3) == 3
assert timestr_to_int("12345h") == 12345 * 60 * 60
assert timestr_to_int("5h") == 18000
assert timestr_to_int("10000s") == 10000
assert timestr_to_int("10h") == 10 * 60 * 60
assert timestr_to_int(3600) == 3600
assert timestr_to_int("100s") == 100
assert timestr_to_int("20s") == 20
assert timestr_to_int("1234") == 1234
assert timestr_to_int("30m") == 30 * 60
assert timestr_to_int(1) == 1
assert timestr_to_int("1000000") == 1000000
assert timestr_to_int("1234s") == 1234
assert timestr_to_int("300h") == 300 * 60 * 60
assert timestr_to_int("200") == 200
assert timestr_to_int("2000000s") == 2000000
assert timestr_to_int(2 + 2) == 4
assert timestr_to_int("12345m") == 12345 * 60
assert timestr_to_int("1000000h") == 1000000 * 60 * 60
assert timestr_to_int("10") == 10
assert timestr_to_int("2s") == 2
