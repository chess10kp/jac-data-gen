"""Drop a key from a dict if it exists and return that change"""
def drop_key_safely(dictionary: Any, key: Any) -> object {
    if (key in dictionary) {
        delete(dictionary[key],);
    }
    return dictionary;
}

test "t0" {
    assert (drop_key_safely(`dict(), "a") == `dict());;
}

test "t1" {
    assert (drop_key_safely({'a': 1, 'b': 2}, 'b') == {'a': 1});;
}

test "t2" {
    assert (
        drop_key_safely({"a": "a", "b": "b", "c": "c"}, "b") == {"a": "a", "c": "c"}
    );;
}

test "t3" {
    assert (drop_key_safely({'a': 1, 'b': 2}, 'a') == {'b': 2});;
}

test "t4" {
    assert (drop_key_safely({"a": "a", "b": "b"}, "b") == {"a": "a"});;
}

test "t5" {
    assert (drop_key_safely({}, "a") == {});;
}

test "t6" {
    assert (drop_key_safely({"a": "a"}, "a") == {});;
}

test "t7" {
    assert (drop_key_safely({'a': 1, 'b': 2, 'c': 3}, 'c') == {'a': 1, 'b': 2});;
}

test "t8" {
    assert (drop_key_safely({'A': 2, 'B': 3, 'C': 4}, 'C') == {'A': 2, 'B': 3});;
}

test "t9" {
    assert (drop_key_safely({'a': 1, 'b': 2}, 'c') == {'a': 1, 'b': 2});;
}

test "t10" {
    assert (drop_key_safely({"a": 1, "b": 2}, "b") == {"a": 1});;
}

test "t11" {
    assert (drop_key_safely({'a': 1}, 'd') == {'a': 1});;
}

test "t12" {
    assert (drop_key_safely({}, 'a') == {});;
}

test "t13" {
    assert (drop_key_safely({}, 'd') == {});;
}

test "t14" {
    assert (drop_key_safely({'a': 1, 'b': 2}, 'b') == {'a': 1});;
}

test "t15" {
    assert (drop_key_safely({"a": 1, "b": 2}, "c") == {"a": 1, "b": 2});;
}

test "t16" {
    assert (drop_key_safely({'a': 1, 'b': 2, 'c': 3}, 'b') == {'a': 1, 'c': 3});;
}

test "t17" {
    assert (
        drop_key_safely({"key1": "value1", "key2": "value2"}, "key1")
        == {"key2": "value2"}
    );;
}

test "t18" {
    assert (drop_key_safely({'a': 1, 'b': 2}, 'b') == {'a': 1});;
}

test "t19" {
    assert (drop_key_safely({'a': 1, 'b': 2, 'c': 3}, 'd') == {'a': 1, 'b': 2, 'c': 3});;
}

test "t20" {
    assert (drop_key_safely(`dict(), 'a') == `dict());;
}

test "t21" {
    assert (drop_key_safely({'a': 1, 'b': 2, 'c': 3}, 'b') == {'a': 1, 'c': 3});;
}

test "t22" {
    assert (
        drop_key_safely({"key1": "value1", "key2": "value2"}, "key2")
        == {"key1": "value1"}
    );;
}

test "t23" {
    assert (drop_key_safely({"a": "a"}, "b") == {"a": "a"});;
}

test "t24" {
    assert (drop_key_safely({"a": "a", "b": "b"}, "a") == {"b": "b"});;
}

test "t25" {
    assert (drop_key_safely({"date": 4}, "date") == {});;
}

test "t26" {
    assert (drop_key_safely({}, 'a') == `dict());;
}

test "t27" {
    assert (drop_key_safely({'a': 1}, 'a') == {});;
}

test "t28" {
    assert (drop_key_safely({'a': 1, 'b': 2, 'c': 3}, 'a') == {'b': 2, 'c': 3});;
}

test "t29" {
    assert (drop_key_safely({'a': 1, 'b': 2}, 'c') == {'a': 1, 'b': 2});;
}

test "t30" {
    assert (drop_key_safely({'a': 1, 'b': 2, 'c': 3}, 'a') == {'b': 2, 'c': 3});;
}

test "t31" {
    assert (drop_key_safely(`dict(), "b") == `dict());;
}

test "t32" {
    assert (drop_key_safely({'a': 1}, 'b') == {'a': 1});;
}

test "t33" {
    assert (drop_key_safely(`dict(), "a") == drop_key_safely(`dict(), "b"));;
}

test "t34" {
    assert (drop_key_safely({'A': 2, 'B': 3, 'C': 4}, 'D') == {'A': 2, 'B': 3, 'C': 4});;
}

test "t35" {
    assert (
        drop_key_safely({"apple": 1, "banana": 2, "clementine": 3, "date": 4}, "date")
        == {"apple": 1, "banana": 2, "clementine": 3}
    );;
}

test "t36" {
    assert (drop_key_safely({'A': 2, 'B': 3, 'C': 4}, 'A') == {'B': 3, 'C': 4});;
}

test "t37" {
    assert (
        drop_key_safely({"key1": "value1", "key2": "value2"}, "key3")
        == {"key1": "value1", "key2": "value2"}
    );;
}

test "t38" {
    assert (
        drop_key_safely({"apple": 1, "banana": 2, "clementine": 3, "date": 4}, "date")
        == {"apple": 1, "banana": 2, "clementine": 3}
    );;
}

test "t39" {
    assert (drop_key_safely({'a': 1, 'b': 2, 'c': 3}, 'c') == {'a': 1, 'b': 2});;
}

test "t40" {
    assert (drop_key_safely({'a': 1, 'b': 2, 'c': 3}, 'd') == {'a': 1, 'b': 2, 'c': 3});;
}

test "t41" {
    assert (drop_key_safely({'a': 1, 'b': 2}, 'a') == {'b': 2});;
}

test "t42" {
    assert (drop_key_safely({'a': 1, 'b': 2}, 'a') == {'b': 2});;
}

test "t43" {
    assert (drop_key_safely({'a': 1, 'b': 2}, 'b') == {'a': 1});;
}

test "t44" {
    assert (drop_key_safely({"a": 1, "b": 2}, "a") == {"b": 2});;
}

test "t45" {
    assert (drop_key_safely({'a': 1, 'b': 2}, 'd') == {'a': 1, 'b': 2});;
}

test "t46" {
    assert (drop_key_safely({'A': 2, 'B': 3, 'C': 4}, 'B') == {'A': 2, 'C': 4});;
}
