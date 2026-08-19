"""Convert bytes to human-readable string (like `-h` option in POSIX).

    Args:
        size (int): Total bytes.
        floating (int, optional): Floating point length. Defaults to 2.
        binary (bool, optional): Format as XB or XiB. Defaults to True.

    Returns:
        str: Human-readable string of size.
    """
def readableSize(byteSize: int, floating: int = 2, binary: bool = True) -> str {
    size = float(byteSize);
    unit = "B";
    if binary {
        for unit in ["B", "kiB", "MiB", "GiB", "TiB", "PiB"] {
            if ((size < 1024.0) or (unit == "PiB")) {
                break;
            }
            size /= 1024.0;
        }
        return f"{size:{floating}}{unit}";
    }
    for unit in ["B", "kB", "MB", "GB", "TB", "PB"] {
        if ((size < 1000.0) or (unit == "PB")) {
            break;
        }
        size /= 1000.0;
    }
    return f"{size:{floating}}{unit}";
}

test "t0" {
    assert (readableSize((1024 ** 5)) == "1.00PiB");;
}

test "t1" {
    assert (readableSize(1234567890) == "1.15GiB");;
}

test "t2" {
    assert (readableSize(1000) == "1000.00B");;
}

test "t3" {
    assert (readableSize(1000, 10) == "1000.0000000000B");;
}

test "t4" {
    assert (readableSize(4398046511104, 2) == "4.00TiB");;
}

test "t5" {
    assert (readableSize(4096) == "4.00kiB");;
}

test "t6" {
    assert (readableSize(1234567890, 0) == "1GiB");;
}

test "t7" {
    assert (readableSize(100, 1) == "100.0B");;
}

test "t8" {
    assert (readableSize(0, 10) == "0.0000000000B");;
}

test "t9" {
    assert (readableSize(2048) == "2.00kiB");;
}

test "t10" {
    assert (readableSize(0, 2) == "0.00B");;
}

test "t11" {
    assert (readableSize((1024 ** 5)) == "1.00PiB");;
}

test "t12" {
    assert (readableSize(0, 5) == "0.00000B");;
}

test "t13" {
    assert (readableSize((1024 ** 3)) == "1.00GiB");;
}

test "t14" {
    assert (readableSize(0, 0) == "0B");;
}

test "t15" {
    assert (readableSize(123456789, 1) == "117.7MiB");;
}

test "t16" {
    assert (readableSize(2097152) == "2.00MiB");;
}

test "t17" {
    assert (readableSize(1024) == "1.00kiB");;
}

test "t18" {
    assert (readableSize((1024 ** 3)) == "1.00GiB");;
}

test "t19" {
    assert (readableSize(1048576) == "1.00MiB");;
}

test "t20" {
    assert (readableSize((1024 ** 4)) == "1.00TiB");;
}

test "t21" {
    assert (readableSize(123456789) == "117.74MiB");;
}

test "t22" {
    assert (readableSize(100, 0) == "100B");;
}

test "t23" {
    assert (readableSize(10, 10) == "10.0000000000B");;
}

test "t24" {
    assert (readableSize((1024 ** 4)) == "1.00TiB");;
}

test "t25" {
    assert (readableSize(40, 2) == "40.00B");;
}

test "t26" {
    assert (readableSize((1024 ** 2)) == "1.00MiB");;
}

test "t27" {
    assert (readableSize(1) == "1.00B");;
}

test "t28" {
    assert (readableSize((1024 ** 2)) == "1.00MiB");;
}

test "t29" {
    assert (readableSize(8192) == "8.00kiB");;
}

test "t30" {
    assert (readableSize(4095) == "4.00kiB");;
}

test "t31" {
    assert (readableSize(1024, 2, False) == "1.02kB");;
}

test "t32" {
    assert (readableSize(1234567890, 0, False) == "1GB");;
}

test "t33" {
    assert (readableSize(1025) == "1.00kiB");;
}

test "t34" {
    assert (readableSize(100, 2) == "100.00B");;
}

test "t35" {
    assert (readableSize(1536) == "1.50kiB");;
}

test "t36" {
    assert (readableSize(100) == "100.00B");;
}
