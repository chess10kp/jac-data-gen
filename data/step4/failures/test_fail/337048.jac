"""Return a dictionary that describes the change since last week using Ben Major's API format.

    One change from Ben Major's format is that new entries will show as an "up" change and the actual and amount
    parts will be computed as if the single or album was at #41 the previous week. Therefore an entry that is straight
    in at number 1, will show an amount and actual move of 40 places.

    >>> change_dict(11,16)
    >>> {"direction": "up", "amount": 5. "actual": 5}

    >>> change_dict(11,0)
    >>> {"direction": "up", "amount": 30. "actual": 30}

    >>> change_dict(16,11)
    >>> {"direction": "down", "amount": 0, "actual": -5}

    >>> change_dict(11,11)
    >>> {"direction": "none", "amount": 0, "actual": 0}

    Args:
        position (:py:class:`int`) : The position in the chart 1-40
        previous (:py:class:`int`) : Last week's chart position

    Returns:
        change_dict (:py:class:`dict`) : A dictionary containing keys that describe the Change since last week
    """
def get_change_dict(position: Any, previous: Any) -> object {
    actual = previous if previous else 41 - position;
    amount = abs(actual);
    if (actual > 0) {
        direction = "up";
    } elif (actual < 0) {
        direction = "down";
    } else {
        direction = "none";
    }
    return `dict(direction=direction, actual=actual, amount=amount);
}

test "t0" {
    assert (get_change_dict(11, 16) == {'amount': 5, 'actual': 5, 'direction': 'up'});;
}

test "t1" {
    assert (get_change_dict(11, 11) == {"direction": "none", "amount": 0, "actual": 0});;
}

test "t2" {
    assert (
        get_change_dict(11, 10) == {"direction": "down", "amount": 1, "actual": -1}
    );;
}

test "t3" {
    assert (get_change_dict(11, 0) == {'amount': 30, 'actual': 30, 'direction': 'up'});;
}

test "t4" {
    assert (get_change_dict(11, 16) == {"direction": "up", "actual": 5, "amount": 5});;
}

test "t5" {
    assert (get_change_dict(11, 11) == {"direction": "none", "actual": 0, "amount": 0});;
}

test "t6" {
    assert (get_change_dict(11, 11) == {"direction": "none", "actual": 0, "amount": 0});;
}

test "t7" {
    assert (get_change_dict(1, 1) == {'direction': 'none', 'amount': 0, 'actual': 0});;
}

test "t8" {
    assert (get_change_dict(11, 0) == {"direction": "up", "amount": 30, "actual": 30});;
}

test "t9" {
    assert (get_change_dict(40, 41) == {"direction": "up", "amount": 1, "actual": 1});;
}

test "t10" {
    assert (get_change_dict(11, 16) == {"direction": "up", "amount": 5, "actual": 5});;
}

test "t11" {
    assert (get_change_dict(11, 0) == {"direction": "up", "actual": 30, "amount": 30});;
}

test "t12" {
    assert (get_change_dict(11, 16) == {"direction": "up", "amount": 5.0, "actual": 5});;
}

test "t13" {
    assert (get_change_dict(11, 16) == {"direction": "up", "actual": 5, "amount": 5});;
}

test "t14" {
    assert (get_change_dict(16, 16) == {"direction": "none", "amount": 0, "actual": 0});;
}

test "t15" {
    assert (get_change_dict(11, 11) == {'amount': 0, 'actual': 0, 'direction': 'none'});;
}

test "t16" {
    assert (
        get_change_dict(11, 0) == {"direction": "up", "amount": 30.0, "actual": 30}
    );;
}

test "t17" {
    assert (get_change_dict(0, 41) == {"direction": "up", "amount": 41, "actual": 41});;
}

test "t18" {
    assert (get_change_dict(11, 16) == {"direction": "up", "amount": 5, "actual": 5});;
}

test "t19" {
    assert (get_change_dict(11, 11) == {"direction": "none", "amount": 0, "actual": 0});;
}
