"""
    show difference
    :param list1:
    :type list1:
    :param list2:
    :type list2:
    :return:
    :rtype:
    """
def find_symmetric_difference(list1: Any, list2: Any) -> object {
    difference = `set(list1).symmetric_difference(`set(list2));
    list_difference = `list(difference);
    return list_difference;
}

test "t0" {
    assert (find_symmetric_difference([1, 1, 2, 2, 3], [1, 1, 2, 2, 3]) == []);;
}

test "t1" {
    assert (find_symmetric_difference([1, 2, 3, 4, 5], [5, 4, 3, 2, 1]) == []);;
}

test "t2" {
    assert (
        find_symmetric_difference([1, 1, 2, 2, 3, 4, 5], [1, 1, 2, 2, 3, 4, 5]) == []
    );;
}

test "t3" {
    assert (
        find_symmetric_difference([1, 2, 3, 4, 5], [5, 6, 7, 8, 9])
        == [1, 2, 3, 4, 6, 7, 8, 9]
    );;
}

test "t4" {
    assert (
        find_symmetric_difference(
            ['apple', 'apple', 'apple'], ['apple', 'apple', 'apple']
        )
        == []
    );;
}

test "t5" {
    assert (find_symmetric_difference([1, 2, 3], [1, 2, 3]) == []);;
}

test "t6" {
    assert (find_symmetric_difference([1, 1, 2, 2, 3], [1, 1, 2, 2]) == [3]);;
}

test "t7" {
    assert (find_symmetric_difference([1, 2, 3, 5], [1, 2, 3, 4, 5]) == [4]);;
}

test "t8" {
    assert (
        find_symmetric_difference(
            ['apple', 'apple', 'apple', 'banana'], ['apple', 'apple', 'apple', 'banana']
        )
        == []
    );;
}

test "t9" {
    assert (
        find_symmetric_difference(`set([1, 2, 3, 5, 7]), `set([])) == [1, 2, 3, 5, 7]
    );;
}

test "t10" {
    assert (find_symmetric_difference([1, 2, 3, 4, 5], [5, 2, 1, 7, 4]) == [3, 7]);;
}

test "t11" {
    assert (find_symmetric_difference([], [1, 2, 3, 4, 5]) == [1, 2, 3, 4, 5]);;
}

test "t12" {
    assert (find_symmetric_difference([1, 2, 3, 4, 5], [1, 2, 5, 7, 5]) == [3, 4, 7]);;
}

test "t13" {
    assert (
        find_symmetric_difference([1, 2, 3, 4, 5], [2, 5, 6, 7, 9])
        == [1, 3, 4, 6, 7, 9]
    );;
}

test "t14" {
    assert (find_symmetric_difference([], [2, 3]) == [2, 3]);;
}

test "t15" {
    assert (find_symmetric_difference([1, 2, 3], [2, 3, 4]) == [1, 4]);;
}

test "t16" {
    assert (
        find_symmetric_difference([1, 2, 3, 4], [5, 6, 7, 8])
        == [1, 2, 3, 4, 5, 6, 7, 8]
    );;
}

test "t17" {
    assert (find_symmetric_difference([1, 2, 3, 4, 5], [1, 2, 3, 4, 5]) == []);;
}

test "t18" {
    assert (
        find_symmetric_difference([1, 1, 2, 2, 3, 4, 5, 6], [1, 1, 2, 2, 3, 4, 5, 6])
        == []
    );;
}

test "t19" {
    assert (
        find_symmetric_difference([1, 2, 3, 4, 5], [5, 2, 10, 10]) == [1, 3, 4, 10]
    );;
}

test "t20" {
    assert (
        find_symmetric_difference(
            ['apple', 'orange', 'mango'], ['banana', 'orange', 'mango']
        )
        == ['banana', 'apple']
    );;
}

test "t21" {
    assert (find_symmetric_difference([], [1, 2, 3, 4, 5]) == [1, 2, 3, 4, 5]);;
}

test "t22" {
    assert (find_symmetric_difference([1, 2, 3, 4, 5], [1, 2, 3, 4, 5, 5, 5, 5]) == []);;
}

test "t23" {
    assert (find_symmetric_difference([1, 2, 3, 4, 5], [1]) == [2, 3, 4, 5]);;
}

test "t24" {
    assert (
        find_symmetric_difference([1, 2, 3, 4], [5, 6, 7, 8])
        == [1, 2, 3, 4, 5, 6, 7, 8]
    );;
}

test "t25" {
    assert (find_symmetric_difference([1, 2, 3, 4, 5], [5, 2, 10]) == [1, 3, 4, 10]);;
}

test "t26" {
    assert (find_symmetric_difference([], []) == []);;
}

test "t27" {
    assert (
        find_symmetric_difference([1, 2, 3, 4, 5], [5, 2, 10, 10, 10]) == [1, 3, 4, 10]
    );;
}

test "t28" {
    assert (find_symmetric_difference([1, 2, 3, 4], [1, 2, 3, 4, 5]) == [5]);;
}

test "t29" {
    assert (
        find_symmetric_difference(
            ['apple', 'orange', 'mango', 'apple'],
            ['banana', 'orange', 'apple', 'mango']
        )
        == ['banana']
    );;
}

test "t30" {
    assert (
        find_symmetric_difference([1, 2, 3, 4, 5], [6, 7, 8, 9, 10])
        == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    );;
}

test "t31" {
    assert (find_symmetric_difference([1, 2, 3, 4], [1, 2, 3, 4]) == []) , "Should be []";;
}

test "t32" {
    assert (find_symmetric_difference([1, 2, 3, 4, 5], [1, 2, 3, 4, 5]) == []);;
}

test "t33" {
    assert (find_symmetric_difference([1, 2, 3, 4, 5], [1, 2, 3, 4]) == [5]);;
}

test "t34" {
    assert (find_symmetric_difference([1, 2, 3, 4], [3, 4, 5, 6]) == [1, 2, 5, 6]) , "Should be [1, 2, 5, 6]";;
}

test "t35" {
    assert (find_symmetric_difference([1, 2, 3, 4], []) == [1, 2, 3, 4]) , "Should be [1, 2, 3, 4]";;
}

test "t36" {
    assert (find_symmetric_difference([1, 2, 3, 4, 5], []) == [1, 2, 3, 4, 5]);;
}

test "t37" {
    assert (find_symmetric_difference([1, 2, 3, 4], [1, 2, 3, 4]) == []);;
}

test "t38" {
    assert (find_symmetric_difference([1], [1, 2, 3, 4, 5]) == [2, 3, 4, 5]);;
}

test "t39" {
    assert (
        find_symmetric_difference([1, 2, 3, 4, 5], [2, 3, 5, 6, 7]) == [1, 4, 6, 7]
    ) , "Should be [1, 4, 6, 7]";;
}

test "t40" {
    assert (find_symmetric_difference([], [1, 2, 3, 4, 5]) == [1, 2, 3, 4, 5]);;
}

test "t41" {
    assert (find_symmetric_difference([1, 2, 3, 4, 5], []) == [1, 2, 3, 4, 5]);;
}

test "t42" {
    assert (
        find_symmetric_difference(
            [1, 2, 3, 4, 5, 6, 7, 8, 9], [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        )
        == [1, 2, 3, 4, 10, 11, 12, 13, 14]
    );;
}

test "t43" {
    assert (find_symmetric_difference([1, 2, 3], []) == [1, 2, 3]);;
}

test "t44" {
    assert (find_symmetric_difference([1, 2, 3, 4, 5], [1, 2, 3, 4, 5]) == []);;
}

test "t45" {
    assert (
        find_symmetric_difference([6, 7, 8, 9, 10], [1, 2, 3, 4, 5])
        == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    );;
}

test "t46" {
    assert (
        find_symmetric_difference(
            [1, 1, 2, 2, 3, 3, 4, 5, 6, 7], [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        )
        == [1, 2, 3, 4, 8, 9, 10, 11, 12, 13, 14]
    );;
}

test "t47" {
    assert (find_symmetric_difference([1, 2, 3, 4, 5], [4, 5, 1, 2, 3]) == []);;
}

test "t48" {
    assert (
        find_symmetric_difference([1, 1, 2, 2, 3, 4, 5], [1, 1, 2, 2, 3, 4, 5, 6])
        == [6]
    );;
}

test "t49" {
    assert (find_symmetric_difference([], [1, 2, 3, 4]) == [1, 2, 3, 4]) , "Should be [1, 2, 3, 4]";;
}

test "t50" {
    assert (
        find_symmetric_difference(
            ['apple', 'orange', 'carrot'], ['banana', 'orange', 'apple']
        )
        == ['banana', 'carrot']
    );;
}

test "t51" {
    assert (
        find_symmetric_difference(`set([]), `set([1, 2, 3, 5, 7])) == [1, 2, 3, 5, 7]
    );;
}
