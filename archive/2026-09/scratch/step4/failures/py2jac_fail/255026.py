def p_assist(assist):
    """
    String of assist operator
    :param assist: assist operator
    :return: lowercase assist operator
    """
    return str(assist).lower()

assert p_assist('a-b*c') == 'a-b*c'
assert p_assist('\'another string\'') == '\'another string\''
assert p_assist(set()) =='set()'
assert p_assist(36) == '36'
assert p_assist(
    "ASSIST_STRAIGHT_LANE_STRAIGHT"
) == "assist_straight_lane_straight"
assert p_assist(1 + 1j) == '(1+1j)'
assert p_assist("at least one") == "at least one"
assert p_assist(
    "ASSIST_RIGHT_LANE_STRAIGHT"
) == "assist_right_lane_straight"
assert p_assist(15) == '15'
assert p_assist(23) == '23'
assert p_assist(
    "ASSIST_LEFT_LANE_LEFT"
) == "assist_left_lane_left"
assert p_assist(1j) == '1j'
assert p_assist(26) == '26'
assert p_assist(11) == '11'
assert p_assist(1) == p_assist('1')
assert p_assist(
    "ASSIST_LEFT_LANE_RIGHT"
) == "assist_left_lane_right"
assert p_assist(18) == '18'
assert p_assist(29) == '29'
assert p_assist(19) == '19'
assert p_assist('1') == '1'
assert p_assist(22) == '22'
assert p_assist('assist') == 'assist'
assert p_assist(None) == p_assist('none')
assert p_assist(30) == '30'
assert p_assist(
    "ASSIST_RIGHT_LANE_LEFT"
) == "assist_right_lane_left"
assert p_assist('assist2') == 'assist2'
assert p_assist(24) == '24'
assert p_assist(37) == '37'
assert p_assist(38) == '38'
assert p_assist(14) == '14'
assert p_assist(33) == '33'
assert p_assist(20) == '20'
assert p_assist({'a': 1}) == "{'a': 1}"
assert p_assist(False) == 'false'
assert p_assist(tuple()) == '()'
assert p_assist('a+b/c') == 'a+b/c'
assert p_assist('none') == 'none'
assert p_assist(list(range(10))) == '[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]'
assert p_assist(list()) == '[]'
assert p_assist(25) == '25'
assert p_assist('assist100') == 'assist100'
assert p_assist(None) == 'none'
assert p_assist(
    "ASSIST_RIGHT_LANE_RIGHT"
) == "assist_right_lane_right"
assert p_assist('a+b-c') == 'a+b-c'
assert p_assist(32) == '32'
assert p_assist('1.5') == '1.5'
assert p_assist("none") == "none"
assert p_assist(1.5) == '1.5'
assert p_assist(35) == '35'
assert p_assist(
    "ASSIST_LEFT_LANE_STRAIGHT"
) == "assist_left_lane_straight"
assert p_assist(17) == '17'
assert p_assist(True) == 'true'
assert p_assist("at most one") == "at most one"
assert p_assist(16) == '16'
assert p_assist(21) == '21'
assert p_assist(13) == '13'
assert p_assist(3) == p_assist('3')
assert p_assist(27) == '27'
assert p_assist("exactly one") == "exactly one"
assert p_assist('assist1') == 'assist1'
assert p_assist('a-b+c') == 'a-b+c'
assert p_assist(34) == '34'
assert p_assist(
    "ASSIST_STRAIGHT_LANE_RIGHT"
) == "assist_straight_lane_right"
assert p_assist(28) == '28'
assert p_assist('a-b/c') == 'a-b/c'
assert p_assist(31) == '31'
assert p_assist(range(10)) == 'range(0, 10)'
assert p_assist(12) == '12'
assert p_assist(tuple(range(10))) == '(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)'
assert p_assist('a+b*c') == 'a+b*c'
assert p_assist(2) == p_assist('2')
assert p_assist(100) == p_assist('100')
assert p_assist(
    "ASSIST_STRAIGHT_LANE_LEFT"
) == "assist_straight_lane_left"
assert p_assist('test') == 'test'
assert p_assist(1) == '1'
assert p_assist('"a string"') == '"a string"'
