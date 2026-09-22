"""

    :param selectpicker_id:
    :return:
    """
def get_follower_ratio_min(selectpicker_id: str) -> int {
    min_values = {
        "1": 0,
        "2": 1,
        "3": 2,
        "4": 3,
        "5": 4,
        "6": 5,
        "7": 6,
        "8": 7,
        "9": 8,
        "10": 9,
        "11": 10,
        "12": 15,
        "13": 20,
        "14": 30,
        "15": 40,
        "16": 50
    };
    return min_values.get(selectpicker_id, 0);
}

test "t0" {
    assert (get_follower_ratio_min("8") == 7);;
}

test "t1" {
    assert (get_follower_ratio_min("2") == 1);;
}

test "t2" {
    assert (get_follower_ratio_min("4") == 3);;
}

test "t3" {
    assert (get_follower_ratio_min("20") == 0);;
}

test "t4" {
    assert (get_follower_ratio_min("14") == 30);;
}

test "t5" {
    assert (get_follower_ratio_min("3") == 2);;
}

test "t6" {
    assert (get_follower_ratio_min(1) == 0);;
}

test "t7" {
    assert (get_follower_ratio_min("7") == 6);;
}

test "t8" {
    assert (get_follower_ratio_min("4") == 3);;
}

test "t9" {
    assert (get_follower_ratio_min("21") == 0);;
}

test "t10" {
    assert (get_follower_ratio_min("1") == 0);;
}

test "t11" {
    assert (get_follower_ratio_min("invalid_input") == 0);;
}

test "t12" {
    assert (get_follower_ratio_min("11") == 10);;
}

test "t13" {
    assert (get_follower_ratio_min("3") == 2);;
}

test "t14" {
    assert (get_follower_ratio_min("0") == 0);;
}

test "t15" {
    assert (get_follower_ratio_min("9") == 8);;
}

test "t16" {
    assert (get_follower_ratio_min("19") == 0);;
}

test "t17" {
    assert (get_follower_ratio_min("17") == 0);;
}

test "t18" {
    assert (get_follower_ratio_min("13") == 20);;
}

test "t19" {
    assert (get_follower_ratio_min("5") == 4);;
}

test "t20" {
    assert (get_follower_ratio_min("6") == 5);;
}

test "t21" {
    assert (get_follower_ratio_min("7") == 6);;
}

test "t22" {
    assert (get_follower_ratio_min("15") == 40);;
}

test "t23" {
    assert (get_follower_ratio_min("12") == 15);;
}

test "t24" {
    assert (get_follower_ratio_min("8") == 7);;
}

test "t25" {
    assert (get_follower_ratio_min("10") == 9);;
}

test "t26" {
    assert (get_follower_ratio_min("6") == 5);;
}

test "t27" {
    assert (get_follower_ratio_min("1") == 0);;
}

test "t28" {
    assert (get_follower_ratio_min("18") == 0);;
}

test "t29" {
    assert (get_follower_ratio_min("5") == 4);;
}

test "t30" {
    assert (get_follower_ratio_min("2") == 1);;
}

test "t31" {
    assert (get_follower_ratio_min("16") == 50);;
}
