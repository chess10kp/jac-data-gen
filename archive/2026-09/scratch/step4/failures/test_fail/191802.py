def get_follower_ratio_min(selectpicker_id: str) -> int:
    """

    :param selectpicker_id:
    :return:
    """
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
    }
    return min_values.get(selectpicker_id, 0)

assert get_follower_ratio_min(
    "8") == 7
assert get_follower_ratio_min("2") == 1
assert get_follower_ratio_min("4") == 3
assert get_follower_ratio_min(
    "20") == 0
assert get_follower_ratio_min(
    "14") == 30
assert get_follower_ratio_min(
    "3") == 2
assert get_follower_ratio_min(1) == 0
assert get_follower_ratio_min("7") == 6
assert get_follower_ratio_min(
    "4") == 3
assert get_follower_ratio_min(
    "21") == 0
assert get_follower_ratio_min("1") == 0
assert get_follower_ratio_min("invalid_input") == 0
assert get_follower_ratio_min(
    "11") == 10
assert get_follower_ratio_min("3") == 2
assert get_follower_ratio_min("0") == 0
assert get_follower_ratio_min(
    "9") == 8
assert get_follower_ratio_min(
    "19") == 0
assert get_follower_ratio_min(
    "17") == 0
assert get_follower_ratio_min(
    "13") == 20
assert get_follower_ratio_min("5") == 4
assert get_follower_ratio_min("6") == 5
assert get_follower_ratio_min(
    "7") == 6
assert get_follower_ratio_min(
    "15") == 40
assert get_follower_ratio_min(
    "12") == 15
assert get_follower_ratio_min("8") == 7
assert get_follower_ratio_min(
    "10") == 9
assert get_follower_ratio_min(
    "6") == 5
assert get_follower_ratio_min(
    "1") == 0
assert get_follower_ratio_min(
    "18") == 0
assert get_follower_ratio_min(
    "5") == 4
assert get_follower_ratio_min(
    "2") == 1
assert get_follower_ratio_min(
    "16") == 50
