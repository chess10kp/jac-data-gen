"""
     in python 3: TypeError: '<' not supported between instances of 'int' and 'str'
     need to keep the same Type of member in List
    """
def unique(data: Any) -> object {
    data.sort();
    l = len(data) - 1;
    i = 0;
    while (i < l) {
        if (data[i] == data[(i + 1)]) {
            delete(data[i],);
            i -= 1;
            l -= 1;
        }
        i += 1;
    }
    return data;
}

test "t0" {
    assert (unique(['A', 'B', 'B', 'C']) == ['A', 'B', 'C']);;
}

test "t1" {
    assert (unique([2, 4, 4, 2, 4, 4, 4, 4, 3, 3, 2, 3, 4, 4, 4]) == [2, 3, 4]);;
}

test "t2" {
    assert (unique([3, 3, 2, 3, 1, 3, 4]) == [1, 2, 3, 4]);;
}

test "t3" {
    assert (unique([1, 1, 1]) == [1]) , "unique([1, 1, 1])";;
}

test "t4" {
    assert (unique(['a', 'b', 'c', 'd', 'e']) == ['a', 'b', 'c', 'd', 'e']);;
}

test "t5" {
    assert (
        unique(['1', '2', '3', '1', '2', '3', '1', '2', '3', '1', '2', '3'])
        == ['1', '2', '3']
    );;
}

test "t6" {
    assert (unique(`list(range(10))) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);;
}

test "t7" {
    assert (unique([]) == []) , "unique([])";;
}

test "t8" {
    assert (unique(['A', 'A', 'A', 'A']) == ['A']);;
}

test "t9" {
    assert (unique([1, 1, 1, 1, 1]) == [1]);;
}

test "t10" {
    assert (unique(unique([1, 1, 2, 2, 3])) == [1, 2, 3]);;
}

test "t11" {
    assert (unique(unique([1, 2, 3, 3, 4, 5])) == [1, 2, 3, 4, 5]);;
}

test "t12" {
    assert (unique([1, 2, 2, 2, 3, 3]) == [1, 2, 3]);;
}

test "t13" {
    assert (unique(['a', 'a', 'a', 'b', 'a', 'a']) == ['a', 'b']);;
}

test "t14" {
    assert (unique([2, 2, 2, 2, 2, 2]) == [2]);;
}

test "t15" {
    assert (unique(unique([1, 2, 3, 4, 5])) == [1, 2, 3, 4, 5]);;
}

test "t16" {
    assert (
        unique(
            [
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b',
                'b'
            ]
        )
        == ['b']
    );;
}

test "t17" {
    assert (unique([1, 2, 3, 2, 2, 1, 2, 1]) == [1, 2, 3]);;
}

test "t18" {
    assert (unique([1, 2, 2, 3, 4, 4, 4]) == [1, 2, 3, 4]);;
}

test "t19" {
    assert (unique(["A", "B", "A", "B", "C"]) == ["A", "B", "C"]);;
}

test "t20" {
    assert (unique([1, 2, 3, 3, 2, 1]) == [1, 2, 3]);;
}

test "t21" {
    assert (unique([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);;
}

test "t22" {
    assert (unique(['a', 'b', 'c', 'd', 'c', 'b', 'a']) == ['a', 'b', 'c', 'd']);;
}

test "t23" {
    assert (unique(['A', 'A', 'A', 'A', 'B', 'B', 'B', 'C']) == ['A', 'B', 'C']);;
}

test "t24" {
    assert (unique(unique([1, 2, 3, 3, 4, 4, 5, 5])) == [1, 2, 3, 4, 5]);;
}

test "t25" {
    assert (unique(["A", "B", "C", "A", "B", "C"]) == ["A", "B", "C"]);;
}

test "t26" {
    assert (
        unique(['a', 'a', 'b', 'c', 'c', 'd', 'd', 'd', 'e'])
        == ['a', 'b', 'c', 'd', 'e']
    );;
}

test "t27" {
    assert (unique(['1', '2', '3', '1', '2', '3']) == ['1', '2', '3']);;
}

test "t28" {
    assert (unique([1, 2, 3, 4, 5, 6, 6]) == [1, 2, 3, 4, 5, 6]);;
}

test "t29" {
    assert (unique([5, 5, 5, 5, 5, 5]) == [5]);;
}

test "t30" {
    assert (
        unique([2, 4, 4, 2, 4, 4, 4, 4, 3, 3, 2, 3, 4, 4, 4, 4, 5, 3, 4, 5])
        == [2, 3, 4, 5]
    );;
}

test "t31" {
    assert (unique([1, 1, 1, 1, 1, 1]) == [1]);;
}

test "t32" {
    assert (unique(["A", "B", "C", "A", "B", "C", "A", "B", "C"]) == ["A", "B", "C"]);;
}

test "t33" {
    assert (unique([1, 1, 2, 2, 3, 3, 3]) == [1, 2, 3]);;
}

test "t34" {
    assert (unique(unique([1, 2, 3, 3, 4, 4, 5])) == [1, 2, 3, 4, 5]);;
}

test "t35" {
    assert (unique(['a']) == ['a']);;
}

test "t36" {
    assert (unique(["hi", "bye", "hi"]) == ["bye", "hi"]);;
}

test "t37" {
    assert (unique([1, 2, 3, 2, 3, 2, 3, 4]) == [1, 2, 3, 4]);;
}

test "t38" {
    assert (unique(["  A", "  B", "  C"]) == ["  A", "  B", "  C"]);;
}

test "t39" {
    assert (unique([1, 1, 1, 2, 2, 2, 3, 3, 3, 1, 1, 2, 3, 3]) == [1, 2, 3]);;
}

test "t40" {
    assert (unique(`list('aAa')) == `list('Aa'));;
}

test "t41" {
    assert (unique([1.1, 1.1, 1.2, 2.2]) == [1.1, 1.2, 2.2]);;
}

test "t42" {
    assert (
        unique(unique([1, 2, 3, 3, 3, 3, 4, 5, 5, 5, 5, 5, 5, 5])) == [1, 2, 3, 4, 5]
    );;
}

test "t43" {
    assert (unique([[], [1]]) == [[], [1]]);;
}

test "t44" {
    assert (
        unique(['A', 'A', 'A', 'A', 'B', 'B', 'B', 'C', 'C', 'C']) == ['A', 'B', 'C']
    );;
}

test "t45" {
    assert (unique(['a', 'a', 'a']) == ['a']);;
}

test "t46" {
    assert (unique(`list('a')) == `list('a'));;
}

test "t47" {
    assert (unique(['a', 'b', 'a', 'c']) == ['a', 'b', 'c']);;
}

test "t48" {
    assert (unique([1, 2, 2, 3, 3, 3]) == [1, 2, 3]);;
}

test "t49" {
    assert (unique(['a', 'b', 'c', 'd']) == ['a', 'b', 'c', 'd']);;
}

test "t50" {
    assert (unique(unique(["a", "a", "a", "b", "b", "c"])) == ["a", "b", "c"]);;
}

test "t51" {
    assert (unique([1, 2, 3, 1]) == [1, 2, 3]);;
}

test "t52" {
    assert (unique([1, 1]) == [1]);;
}

test "t53" {
    assert (unique(unique([1, 1, 2, 3, 3, 3, 4])) == [1, 2, 3, 4]);;
}

test "t54" {
    assert (unique([1, 2, 3, 2, 3, 4]) == [1, 2, 3, 4]);;
}

test "t55" {
    assert (unique([2.1, 2.2, 2.3, 2.3, 2.2, 2.1]) == [2.1, 2.2, 2.3]);;
}

test "t56" {
    assert (unique([1, 2, 1, 1, 2]) == [1, 2]);;
}

test "t57" {
    assert (unique([1, 2, 3, 4, 5, 6]) == [1, 2, 3, 4, 5, 6]);;
}

test "t58" {
    assert (unique([1, 2, 3, 4, 5]) == [1, 2, 3, 4, 5]);;
}

test "t59" {
    assert (unique([1, 2, 2, 3, 4, 5, 6]) == [1, 2, 3, 4, 5, 6]);;
}

test "t60" {
    assert (unique(['a', 'a', 'a', 'b', 'a', 'b', 'a', 'c']) == ['a', 'b', 'c']);;
}

test "t61" {
    assert (unique(['hello', 'hi', 'hello']) == ['hello', 'hi']);;
}

test "t62" {
    assert (unique(['a', 'b', 'c']) == ['a', 'b', 'c']);;
}

test "t63" {
    assert (unique(unique([])) == []);;
}

test "t64" {
    assert (unique(unique([1, 1, 1, 1, 1, 1])) == [1]);;
}

test "t65" {
    assert (unique(unique([1, 1, 2, 2, 3, 4, 4, 4])) == [1, 2, 3, 4]);;
}

test "t66" {
    assert (unique([]) == []);;
}

test "t67" {
    assert (unique([1, 1, 2, 2, 3, 3]) == [1, 2, 3]);;
}

test "t68" {
    assert (unique([1, 1, 1, 2, 2, 2, 3, 3, 3]) == [1, 2, 3]);;
}

test "t69" {
    assert (unique(unique([1, 2, 3])) == [1, 2, 3]);;
}

test "t70" {
    assert (unique(`list('123123123123123')) == ['1', '2', '3']);;
}

test "t71" {
    assert (unique([1, 1, 1, 1, 1, 1, 1, 1, 1, 2]) == [1, 2]);;
}

test "t72" {
    assert (unique(`list('123123')) == ['1', '2', '3']);;
}

test "t73" {
    assert (unique([1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4]) == [1, 2, 3, 4]);;
}

test "t74" {
    assert (unique(`list('AaAa')) == `list('Aa'));;
}

test "t75" {
    assert (unique(`list('123123123123')) == ['1', '2', '3']);;
}

test "t76" {
    assert (unique([1, 2, 3, 2, 1]) == [1, 2, 3]);;
}

test "t77" {
    assert (unique([1, 2, 3, 2, 1, 3, 2, 2]) == [1, 2, 3]);;
}

test "t78" {
    assert (
        unique([1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5])
        == [1, 2, 3, 4, 5]
    );;
}

test "t79" {
    assert (unique([1]) == [1]);;
}

test "t80" {
    assert (unique([1, 1, 2, 3, 3, 3, 4]) == [1, 2, 3, 4]);;
}

test "t81" {
    assert (unique(['A', 'B', 'C', 'D', 'E']) == ['A', 'B', 'C', 'D', 'E']);;
}

test "t82" {
    assert (unique([1, 2, 1]) == [1, 2]);;
}

test "t83" {
    assert (unique(['a', 'a', 'a', 'a']) == ['a']);;
}

test "t84" {
    assert (
        unique([1, 2, 3, 4, 5, 6, 6, 6, 7, 7, 7, 7, 8, 9, 10])
        == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    );;
}

test "t85" {
    assert (
        unique(
            [1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]
        )
        == [1, 3]
    );;
}

test "t86" {
    assert (unique([1, 1, 2, 2, 2, 3, 3, 3]) == [1, 2, 3]);;
}

test "t87" {
    assert (unique(unique([1, 2, 3, 4, 1, 2, 3, 4])) == [1, 2, 3, 4]);;
}

test "t88" {
    assert (unique([1, 2]) == [1, 2]);;
}

test "t89" {
    assert (unique([1, 1, 2, 1]) == [1, 2]);;
}

test "t90" {
    assert (unique(unique([1, 2, 3, 3, 4, 4, 5, 5, 6])) == [1, 2, 3, 4, 5, 6]);;
}

test "t91" {
    assert (unique([1, 2, 3, 1, 2, 3]) == [1, 2, 3]);;
}

test "t92" {
    assert (unique([1, 2, 3, 2, 3, 4, 2, 3, 4, 5]) == [1, 2, 3, 4, 5]);;
}

test "t93" {
    assert (
        unique(['a', 'b', 'c', 'd', 'e', 'f', 'g'])
        == ['a', 'b', 'c', 'd', 'e', 'f', 'g']
    );;
}

test "t94" {
    assert (unique(['a', 'a', 'b', 'b', 'c', 'd']) == ['a', 'b', 'c', 'd']);;
}

test "t95" {
    assert (unique(unique([1, 1, 1, 1, 1, 1, 1, 1])) == [1]);;
}

test "t96" {
    assert (
        unique(['cat', 'dog', 'cat', 'goldfish', 'dog']) == ['cat', 'dog', 'goldfish']
    );;
}

test "t97" {
    assert (unique(unique(["hi", "hi", "bye"])) == ["bye", "hi"]);;
}

test "t98" {
    assert (unique(["A", "A", "A", "A"]) == ["A"]);;
}

test "t99" {
    assert (unique([1, 2, 3, 1, 2, 3, 1, 2, 3]) == [1, 2, 3]);;
}

test "t100" {
    assert (unique([1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3]) == [1, 2, 3]);;
}

test "t101" {
    assert (unique(["a", "b", "c"]) == ["a", "b", "c"]);;
}

test "t102" {
    assert (unique(["  A  ", "  B  ", "  C  "]) == ["  A  ", "  B  ", "  C  "]);;
}

test "t103" {
    assert (unique(['a', 'a', 'b', 'b', 'c', 'c', 'c']) == ['a', 'b', 'c']);;
}

test "t104" {
    assert (unique([1, 2, 2, 3, 3, 3, 4, 5]) == [1, 2, 3, 4, 5]);;
}

test "t105" {
    assert (unique([2.7, 2.7]) == [2.7]);;
}

test "t106" {
    assert (unique(['a', 'a', 'b', 'b', 'c', 'c']) == ['a', 'b', 'c']);;
}

test "t107" {
    assert (unique([1, 2, 1, 3, 1, 2, 3]) == [1, 2, 3]);;
}

test "t108" {
    assert (unique([1, 2, 3]) == [1, 2, 3]);;
}

test "t109" {
    assert (unique(["B", "B", "C", "D", "B", "A", "C", "B"]) == ["A", "B", "C", "D"]);;
}

test "t110" {
    assert (unique(['A', 'A', 'B', 'C']) == ['A', 'B', 'C']);;
}

test "t111" {
    assert (unique(['1', '2', '3', '1', '2', '3', '1', '2', '3']) == ['1', '2', '3']);;
}

test "t112" {
    assert (unique([4, 4, 4, 4, 4, 4]) == [4]);;
}

test "t113" {
    assert (
        unique([1, 2, 3, 4, 5, 5, 6, 7, 7, 7, 8, 8, 9, 9, 10])
        == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    );;
}

test "t114" {
    assert (unique(unique([1])) == [1]);;
}

test "t115" {
    assert (unique([1, 1, 2, 3, 3, 3]) == [1, 2, 3]);;
}

test "t116" {
    assert (unique(['a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'b']) == ['a', 'b']);;
}

test "t117" {
    assert (unique(["hi", "hi", "bye"]) == ["bye", "hi"]);;
}

test "t118" {
    assert (unique(["A  ", "B  ", "C  "]) == ["A  ", "B  ", "C  "]);;
}

test "t119" {
    assert (unique([3, 3, 3, 3, 3, 3]) == [3]);;
}

test "t120" {
    assert (unique([1, 1, 1, 1]) == [1]);;
}

test "t121" {
    assert (unique([1, 2, 3, 4, 1, 2, 3, 4]) == [1, 2, 3, 4]);;
}

test "t122" {
    assert (
        unique([1, 1, 2, 3, 4, 4, 5, 6, 7, 8, 8, 9, 10, 11, 11])
        == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    );;
}

test "t123" {
    assert (unique(unique([1, 1, 2, 3, 3, 4, 5])) == [1, 2, 3, 4, 5]);;
}

test "t124" {
    assert (unique(["A", "B", "C"]) == ["A", "B", "C"]);;
}
