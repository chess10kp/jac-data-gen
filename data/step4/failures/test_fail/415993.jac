"""Sort a list."""
def mergesort(unsorted_list: Any) -> object {
    if (len(unsorted_list) > 1) {
        mid = len(unsorted_list) // 2;
        left_half = unsorted_list[:mid];
        right_half = unsorted_list[mid:];
        mergesort(left_half);
        mergesort(right_half);
        i = 0;
        j = 0;
        k = 0;
        while ((i < len(left_half)) and (j < len(right_half))) {
            if (left_half[i] < right_half[j]) {
                unsorted_list[k] = left_half[i];
                i = i + 1;
            } else {
                unsorted_list[k] = right_half[j];
                j = j + 1;
            }
            k = k + 1;
        }
        while (i < len(left_half)) {
            unsorted_list[k] = left_half[i];
            i = i + 1;
            k = k + 1;
        }
        while (j < len(right_half)) {
            unsorted_list[k] = right_half[j];
            j = j + 1;
            k = k + 1;
        }
        return unsorted_list;
    }
}

test "t0" {
    assert (mergesort([1, 2, 3, 4, 5, 6]) == [1, 2, 3, 4, 5, 6]);;
}

test "t1" {
    assert (mergesort(`list('214356')) == ['1', '2', '3', '4', '5', '6']);;
}

test "t2" {
    assert (mergesort(`list('abc')) == `list('abc'));;
}

test "t3" {
    assert (mergesort([1, 4, 10, 2, 3, 8, 0]) == [0, 1, 2, 3, 4, 8, 10]);;
}

test "t4" {
    assert (mergesort(`list("ba")) == `list("ab"));;
}

test "t5" {
    assert (mergesort(`list(range(6))) == `list(range(6)));;
}

test "t6" {
    assert (mergesort(`list([4, 1, 3, 2])) == `list([1, 2, 3, 4]));;
}

test "t7" {
    assert (mergesort([4, 1, 2, 3]) == [1, 2, 3, 4]);;
}

test "t8" {
    assert (mergesort(`list('abcde')) == ['a', 'b', 'c', 'd', 'e']);;
}

test "t9" {
    assert (
        mergesort(['f', 't', 'c', 'a', 'g', 's']) == ['a', 'c', 'f', 'g', 's', 't']
    );;
}

test "t10" {
    assert (mergesort([1, 5, 8, 3, 4, 6, 9, 7, 2]) == [1, 2, 3, 4, 5, 6, 7, 8, 9]);;
}

test "t11" {
    assert (mergesort([1, 1, 1, 1, 1, 1, 1]) == [1, 1, 1, 1, 1, 1, 1]);;
}

test "t12" {
    assert (mergesort(`list('cba')) == ['a', 'b', 'c']);;
}

test "t13" {
    assert (mergesort([314, 5, -1, -6, 2, 415]) == [-6, -1, 2, 5, 314, 415]);;
}

test "t14" {
    assert (mergesort(`list('abcd')) == ['a', 'b', 'c', 'd']);;
}

test "t15" {
    assert (mergesort(`list('fedcba')) == `list('abcdef'));;
}

test "t16" {
    assert (mergesort([5, 4, 3, 2, 1]) == [1, 2, 3, 4, 5]);;
}

test "t17" {
    assert (mergesort(`list('abcdab')) == ['a', 'a', 'b', 'b', 'c', 'd']);;
}

test "t18" {
    assert (mergesort([1, 1, 1, 1, 1]) == [1, 1, 1, 1, 1]);;
}

test "t19" {
    assert (mergesort(`list('baab')) == ['a', 'a', 'b', 'b']);;
}

test "t20" {
    assert (mergesort(`list(range(20))) == `list(range(20)));;
}

test "t21" {
    assert (mergesort([1, 2, 3, 4, 5, 6, 7, 8]) == [1, 2, 3, 4, 5, 6, 7, 8]);;
}

test "t22" {
    assert (mergesort(`list("abcde")) == `list("abcde"));;
}

test "t23" {
    assert (mergesort([1, 1, 1, 1, 1, 1, 1, 1]) == [1, 1, 1, 1, 1, 1, 1, 1]);;
}

test "t24" {
    assert (mergesort(`list(range(4))) == [0, 1, 2, 3]);;
}

test "t25" {
    assert (mergesort([1, 3, 2, 5, 6, 7, 0]) == [0, 1, 2, 3, 5, 6, 7]);;
}

test "t26" {
    assert (mergesort([1, 3, 2]) == [1, 2, 3]);;
}

test "t27" {
    assert (mergesort(`list('213456')) == ['1', '2', '3', '4', '5', '6']);;
}

test "t28" {
    assert (mergesort(`list('1245367')) == ['1', '2', '3', '4', '5', '6', '7']);;
}

test "t29" {
    assert (mergesort(`list("gfedcba")) == `list("abcdefg"));;
}

test "t30" {
    assert (mergesort(`list("ab")) == `list("ab"));;
}

test "t31" {
    assert (mergesort(`list(reversed(range(100)))) == `list(range(100)));;
}

test "t32" {
    assert (mergesort(`list([1, 2, 3, 4])) == `list([1, 2, 3, 4]));;
}

test "t33" {
    assert (mergesort([1, 2, 3, 4, 5]) == [1, 2, 3, 4, 5]);;
}

test "t34" {
    assert (mergesort(`list(range(12))) == `list(range(12)));;
}

test "t35" {
    assert (mergesort(`list([2, 3, 1])) == `list([1, 2, 3]));;
}

test "t36" {
    assert (mergesort(`list([1, 2, 3])) == `list([1, 2, 3]));;
}

test "t37" {
    assert (mergesort(`list("cdab")) == `list("abcd"));;
}

test "t38" {
    assert (mergesort([1, 3, 5, 7, 9]) == [1, 3, 5, 7, 9]);;
}

test "t39" {
    assert (mergesort([-10, -1, 0, 10, 100]) == [-10, -1, 0, 10, 100]);;
}

test "t40" {
    assert (
        mergesort([1000, -5, 8, -3, 4, 6, -9, 7, 2])
        == [-9, -5, -3, 2, 4, 6, 7, 8, 1000]
    );;
}

test "t41" {
    assert (mergesort(`list(range(5))) == [0, 1, 2, 3, 4]);;
}

test "t42" {
    assert (
        mergesort([1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20])
        == [1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
    );;
}

test "t43" {
    assert (mergesort([1, 2]) == [1, 2]);;
}

test "t44" {
    assert (mergesort(`list(range(200))) == `list(range(200)));;
}

test "t45" {
    assert (mergesort(`list('4321')) == ['1', '2', '3', '4']);;
}

test "t46" {
    assert (mergesort(`list('abba')) == ['a', 'a', 'b', 'b']);;
}

test "t47" {
    assert (mergesort([3, 5, 1, 6, 2, 4]) == [1, 2, 3, 4, 5, 6]);;
}

test "t48" {
    assert (mergesort([1, 4, 5, 2, 3, 8]) == [1, 2, 3, 4, 5, 8]);;
}

test "t49" {
    assert (mergesort([5, 2, 1, 6, 4, 3, 7]) == [1, 2, 3, 4, 5, 6, 7]) , "Incorrect result for mergesort.";;
}

test "t50" {
    assert (mergesort([1, 3, 2, 4]) == [1, 2, 3, 4]);;
}

test "t51" {
    assert (mergesort([4, 3, 1, 2]) == [1, 2, 3, 4]);;
}

test "t52" {
    assert (mergesort([1, 4, 3, 2]) == [1, 2, 3, 4]);;
}

test "t53" {
    assert (mergesort([1, 2, 3]) == [1, 2, 3]);;
}

test "t54" {
    assert (mergesort(`list(range(7))) == `list(range(7)));;
}

test "t55" {
    assert (mergesort(`list('235146')) == ['1', '2', '3', '4', '5', '6']);;
}

test "t56" {
    assert (mergesort(`list([1, 2, 4, 3])) == `list([1, 2, 3, 4]));;
}

test "t57" {
    assert (mergesort(`list(range(19))) == `list(range(19)));;
}

test "t58" {
    assert (mergesort(`list(range(15))) == `list(range(15)));;
}

test "t59" {
    assert (mergesort(`list('edcba')) == ['a', 'b', 'c', 'd', 'e']);;
}

test "t60" {
    assert (mergesort(`list(range(2))) == [0, 1]);;
}

test "t61" {
    assert (mergesort(`list("dcba")) == `list("abcd"));;
}

test "t62" {
    assert (mergesort(`list([2, 1, 3])) == `list([1, 2, 3]));;
}

test "t63" {
    assert (mergesort(`list('231456')) == ['1', '2', '3', '4', '5', '6']);;
}

test "t64" {
    assert (mergesort([2, 1, 3]) == [1, 2, 3]);;
}

test "t65" {
    assert (mergesort(`list(range(16))) == `list(range(16)));;
}

test "t66" {
    assert (
        mergesort([10, 9, 8, 7, 6, 5, 4, 3, 2, 1]) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    );;
}

test "t67" {
    assert (mergesort(`list('fedcba')) == ['a', 'b', 'c', 'd', 'e', 'f']);;
}

test "t68" {
    assert (mergesort(`list(range(1, 10))) == `list(range(1, 10)));;
}

test "t69" {
    assert (mergesort(`list('cba')) == `list('abc'));;
}

test "t70" {
    assert (mergesort([3, 1]) == [1, 3]);;
}

test "t71" {
    assert (
        mergesort([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
        == [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
    );;
}

test "t72" {
    assert (
        mergesort([1, 4, 2, 6, 2, 5, 7, 9, 1, 3, 5, 7, 8, 9, 6])
        == [1, 1, 2, 2, 3, 4, 5, 5, 6, 6, 7, 7, 8, 9, 9]
    );;
}

test "t73" {
    assert (mergesort(`list(reversed(range(20)))) == `list(range(20)));;
}

test "t74" {
    assert (mergesort(`list("cba")) == `list("abc"));;
}

test "t75" {
    assert (
        mergesort([1, 3, 5, 7, 9, 2, 4, 6, 8, 10]) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    );;
}

test "t76" {
    assert (mergesort(`list("edcba")) == `list("abcde"));;
}

test "t77" {
    assert (mergesort(`list('abab')) == ['a', 'a', 'b', 'b']);;
}

test "t78" {
    assert (mergesort(`list([4, 1, 2, 3])) == `list([1, 2, 3, 4]));;
}

test "t79" {
    assert (mergesort([1, 5, 8, 3, 4, 6, 9, 7, 2]) == [1, 2, 3, 4, 5, 6, 7, 8, 9]);;
}

test "t80" {
    assert (mergesort(`list(range(9))) == `list(range(9)));;
}

test "t81" {
    assert (mergesort(`list('cbaa')) == ['a', 'a', 'b', 'c']);;
}

test "t82" {
    assert (mergesort(`list([1, 3, 2])) == `list([1, 2, 3]));;
}

test "t83" {
    assert (mergesort([4, 2, 1, 3]) == [1, 2, 3, 4]);;
}

test "t84" {
    assert (mergesort(`list('aaa')) == ['a', 'a', 'a']);;
}

test "t85" {
    assert (
        mergesort(`list('zyxwvutsrqponmlkjihgfedcba'))
        == [
            'a',
            'b',
            'c',
            'd',
            'e',
            'f',
            'g',
            'h',
            'i',
            'j',
            'k',
            'l',
            'm',
            'n',
            'o',
            'p',
            'q',
            'r',
            's',
            't',
            '',
            'v',
            'w',
            'x',
            'y',
            'z'
        ]
    );;
}

test "t86" {
    assert (mergesort(`list('hello')) == `list('ehllo'));;
}

test "t87" {
    assert (mergesort(`list(range(3))) == [0, 1, 2]);;
}

test "t88" {
    assert (mergesort(`list(range(14))) == `list(range(14)));;
}

test "t89" {
    assert (mergesort(`list('12345')) == ['1', '2', '3', '4', '5']);;
}

test "t90" {
    assert (mergesort(`list(range(18))) == `list(range(18)));;
}

test "t91" {
    assert (mergesort([2, 1, 3, 4]) == [1, 2, 3, 4]);;
}

test "t92" {
    assert (mergesort(`list('ab')) == `list('ab'));;
}

test "t93" {
    assert (mergesort([314, 5, 1, 6, 2, 415]) == [1, 2, 5, 6, 314, 415]);;
}

test "t94" {
    assert (mergesort([1, 3, 4, 2]) == [1, 2, 3, 4]);;
}

test "t95" {
    assert (mergesort(`list(range(8))) == `list(range(8)));;
}

test "t96" {
    assert (mergesort(`list('6541237')) == ['1', '2', '3', '4', '5', '6', '7']);;
}

test "t97" {
    assert (mergesort([-5, -4, -3, -2, -1]) == [-5, -4, -3, -2, -1]);;
}

test "t98" {
    assert (mergesort([1, 2, 3, 4, 5, 6, 7]) == [1, 2, 3, 4, 5, 6, 7]);;
}

test "t99" {
    assert (mergesort(`list(range(3))) == `list(range(3)));;
}

test "t100" {
    assert (mergesort(`list([2, 1])) == `list([1, 2]));;
}

test "t101" {
    assert (mergesort(`list(range(11))) == `list(range(11)));;
}

test "t102" {
    assert (mergesort(`list("abc")) == `list("abc"));;
}

test "t103" {
    assert (mergesort([-2, -1, 0, 1, 2]) == [-2, -1, 0, 1, 2]);;
}

test "t104" {
    assert (mergesort(`list('7365142')) == ['1', '2', '3', '4', '5', '6', '7']);;
}

test "t105" {
    assert (
        mergesort([1000, 5, 8, 3, 4, 6, 9, 7, 2]) == [2, 3, 4, 5, 6, 7, 8, 9, 1000]
    );;
}

test "t106" {
    assert (mergesort([2, 3, 1]) == [1, 2, 3]);;
}

test "t107" {
    assert (mergesort([3, 1, 2]) == [1, 2, 3]);;
}

test "t108" {
    assert (mergesort([9, 7, 5, 3, 1]) == [1, 3, 5, 7, 9]);;
}

test "t109" {
    assert (mergesort(`list(range(100))[::-1]) == `list(range(100)));;
}

test "t110" {
    assert (mergesort([1, 2, 3, 4]) == [1, 2, 3, 4]);;
}

test "t111" {
    assert (mergesort(`list([3, 1, 2])) == `list([1, 2, 3]));;
}

test "t112" {
    assert (mergesort(`list(range(5))) == `list(range(5)));;
}

test "t113" {
    assert (mergesort(`list(range(10))) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);;
}

test "t114" {
    assert (mergesort(`list('bac')) == `list('abc'));;
}

test "t115" {
    assert (mergesort([1, 3, 4, 1, 2, 5, 6]) == [1, 1, 2, 3, 4, 5, 6]);;
}

test "t116" {
    assert (mergesort([1, 4, 2, 3]) == [1, 2, 3, 4]);;
}

test "t117" {
    assert (
        mergesort(['g', 's', 'f', 't', 'c', 'a']) == ['a', 'c', 'f', 'g', 's', 't']
    );;
}

test "t118" {
    assert (mergesort(`list('edcba')) == `list('abcde'));;
}

test "t119" {
    assert (
        mergesort([9, 8, 7, 6, 5, 4, 3, 2, 1, 0]) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    );;
}

test "t120" {
    assert (
        mergesort([1, 3, 5, 7, 9, 2, 4, 6, 8, 0]) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    );;
}

test "t121" {
    assert (mergesort(`list(range(17))) == `list(range(17)));;
}

test "t122" {
    assert (mergesort(`list(range(13))) == `list(range(13)));;
}

test "t123" {
    assert (mergesort(`list('abcdebc')) == ['a', 'b', 'b', 'c', 'c', 'd', 'e']);;
}

test "t124" {
    assert (mergesort([1, 2, 4, 3]) == [1, 2, 3, 4]);;
}

test "t125" {
    assert (mergesort(`list(range(4))) == `list(range(4)));;
}

test "t126" {
    assert (mergesort([3, 2, 1]) == [1, 2, 3]);;
}

test "t127" {
    assert (mergesort([1, 4, 5, 2, 7, 8, 3, 1]) == [1, 1, 2, 3, 4, 5, 7, 8]);;
}

test "t128" {
    assert (mergesort(`list("abcd")) == `list("abcd"));;
}

test "t129" {
    assert (mergesort([1, 1, 1, 1, 1, 1]) == [1, 1, 1, 1, 1, 1]);;
}

test "t130" {
    assert (mergesort(`list('abc')) == ['a', 'b', 'c']);;
}

test "t131" {
    assert (mergesort(`list([3, 2, 1])) == `list([1, 2, 3]));;
}

test "t132" {
    assert (mergesort(`list('3671245')) == ['1', '2', '3', '4', '5', '6', '7']);;
}

test "t133" {
    assert (mergesort(`list('abcde')) == `list('abcde'));;
}

test "t134" {
    assert (mergesort(`list('ab')) == ['a', 'b']);;
}

test "t135" {
    assert (mergesort(`list([1, 4, 2, 3])) == `list([1, 2, 3, 4]));;
}

test "t136" {
    assert (mergesort(`list(range(100))) == `list(range(100)));;
}

test "t137" {
    assert (mergesort(`list([1, 2])) == `list([1, 2]));;
}

test "t138" {
    assert (mergesort([2, 1]) == [1, 2]);;
}

test "t139" {
    assert (mergesort([1, 2, 3, 4, 5, 6, 7, 8, 9]) == [1, 2, 3, 4, 5, 6, 7, 8, 9]);;
}

test "t140" {
    assert (mergesort([3, 4, 1, 2]) == [1, 2, 3, 4]);;
}

test "t141" {
    assert (mergesort(`list("fedcba")) == `list("abcdef"));;
}

test "t142" {
    assert (
        mergesort(['t', 'c', 'a', 'g', 's', 'f']) == ['a', 'c', 'f', 'g', 's', 't']
    );;
}

test "t143" {
    assert (
        mergesort([20, 18, 16, 14, 12, 10, 8, 6, 4, 2, 1])
        == [1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
    );;
}

test "t144" {
    assert (mergesort([4, 3, 2, 1, 1]) == [1, 1, 2, 3, 4]);;
}

test "t145" {
    assert (mergesort(`list(reversed(range(200)))) == `list(range(200)));;
}

test "t146" {
    assert (
        mergesort(['s', 'f', 't', 'c', 'a', 'g']) == ['a', 'c', 'f', 'g', 's', 't']
    );;
}

test "t147" {
    assert (mergesort(`list('hello world')) == `list(' dehllloorw'));;
}

test "t148" {
    assert (mergesort(`list(range(2))) == `list(range(2)));;
}

test "t149" {
    assert (mergesort(`list(range(10))) == `list(range(10)));;
}

test "t150" {
    assert (mergesort([1, 2, 4, 7, 3, 9, 5, 6, 8]) == [1, 2, 3, 4, 5, 6, 7, 8, 9]);;
}

test "t151" {
    assert (mergesort([3, 2, 1]) == [1, 2, 3]) , "Incorrect result for mergesort.";;
}

test "t152" {
    assert (
        mergesort(`list('abcdefghijklmnopqrstuvwxyz'))
        == `list('abcdefghijklmnopqrstuvwxyz')
    );;
}

test "t153" {
    assert (mergesort([1, 2, 5, 4, 3]) == [1, 2, 3, 4, 5]);;
}

test "t154" {
    assert (mergesort([3, 5, 2, 1, 8]) == [1, 2, 3, 5, 8]);;
}

test "t155" {
    assert (mergesort(`list('1652347')) == ['1', '2', '3', '4', '5', '6', '7']);;
}
