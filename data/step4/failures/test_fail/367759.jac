"""Return a relative path only if it's under $PWD (or `relto`)"""
def bestrelpath(path: Any, relto: Any = None) -> object {
    if (relto is None) {
        import from os { getcwd }
        relto = getcwd();
    }
    import from os.path { relpath }
    relpath = relpath(path, relto);
    if relpath.startswith('.') {
        return path;
    } else {
        return relpath;
    }
}

test "t0" {
    assert (bestrelpath('/foo', '/foo') == '/foo');;
}

test "t1" {
    assert (bestrelpath('a') == 'a');;
}

test "t2" {
    assert (bestrelpath('foo', '.') == 'foo');;
}

test "t3" {
    assert (bestrelpath('/a/b', 'a') == '/a/b');;
}

test "t4" {
    assert (bestrelpath(r'foo/bar/baz', r'/foo/bar/baz/quux/quux') == r'foo/bar/baz');;
}

test "t5" {
    assert (bestrelpath('a', '.') == 'a');;
}

test "t6" {
    assert (bestrelpath(r'foo\bar', r'foo\baz') == r'foo\bar');;
}

test "t7" {
    assert (bestrelpath(r'C:\Users\Foo', r'C:\Users\Baz') == r'C:\Users\Foo');;
}

test "t8" {
    assert (bestrelpath('a/b', '.') == 'a/b');;
}

test "t9" {
    assert (bestrelpath('/foo/bar') == '/foo/bar');;
}

test "t10" {
    assert (bestrelpath('abc/def', 'abc/') == 'def');;
}

test "t11" {
    assert (bestrelpath(r'foo/bar/baz') == r'foo/bar/baz');;
}

test "t12" {
    assert (bestrelpath('/a/b/c', 'a/b') == '/a/b/c');;
}

test "t13" {
    assert (bestrelpath('.') == '.');;
}

test "t14" {
    assert (
        bestrelpath(r'c:\windows\system32\cmd.exe') == r'c:\windows\system32\cmd.exe'
    );;
}

test "t15" {
    assert (bestrelpath(r'a\b\c') == r'a\b\c');;
}

test "t16" {
    assert (bestrelpath('abc', 'abc/def/ghi') == 'abc');;
}

test "t17" {
    assert (bestrelpath('abc', '') == 'abc');;
}

test "t18" {
    assert (bestrelpath(r'c:/a', r'b') == r'c:/a');;
}

test "t19" {
    assert (bestrelpath(r'c:\a', r'/b') == r'c:\a');;
}

test "t20" {
    assert (bestrelpath('a', '') == 'a');;
}

test "t21" {
    assert (bestrelpath(r'foo\bar', r'foo') == r'foo\bar');;
}

test "t22" {
    assert (bestrelpath('a/b', 'a/') == 'b');;
}

test "t23" {
    assert (bestrelpath('c:\\temp\\Špéciale') == 'c:\\temp\\Špéciale');;
}

test "t24" {
    assert (bestrelpath('/foo', '/bar') == '/foo');;
}

test "t25" {
    assert (bestrelpath(r'c:/a', r'/b') == r'c:/a');;
}

test "t26" {
    assert (bestrelpath('bar.txt', '.') == 'bar.txt');;
}

test "t27" {
    assert (bestrelpath('bar.txt', 'foo') == 'bar.txt');;
}

test "t28" {
    assert (bestrelpath('a/b/c', 'a/b/') == 'c');;
}

test "t29" {
    assert (bestrelpath(r'/foo/bar/baz', r'/') == r'foo/bar/baz');;
}

test "t30" {
    assert (bestrelpath(r'c:\windows\system32') == r'c:\windows\system32');;
}

test "t31" {
    assert (bestrelpath('a/b', 'a/') == 'b');;
}

test "t32" {
    assert (bestrelpath(r'/a', r'b') == r'/a');;
}

test "t33" {
    assert (
        bestrelpath(r'C:\Users\Foo\bar', r'C:\Users\Baz\bar') == r'C:\Users\Foo\bar'
    );;
}

test "t34" {
    assert (bestrelpath(r'C:\Users\Foo') == r'C:\Users\Foo');;
}

test "t35" {
    assert (bestrelpath('C:\\Users\\Foo') == r'C:\Users\Foo');;
}

test "t36" {
    assert (bestrelpath('/foo/bar', '/foo/baz') == '/foo/bar');;
}

test "t37" {
    assert (bestrelpath('/foo/bar/', '/foo') == 'bar');;
}

test "t38" {
    assert (bestrelpath('f') == 'f');;
}

test "t39" {
    assert (bestrelpath('abc/def', 'abc') == 'def');;
}

test "t40" {
    assert (bestrelpath('a', '.') == 'a');;
}

test "t41" {
    assert (bestrelpath('/a/b', 'a/c') == '/a/b');;
}

test "t42" {
    assert (bestrelpath('abc', 'abc/def/') == 'abc');;
}

test "t43" {
    assert (bestrelpath(r'a/b', r'a') == r'b');;
}

test "t44" {
    assert (bestrelpath('/foo') == '/foo');;
}

test "t45" {
    assert (bestrelpath('/home/guido/python', '/home/guido') == 'python');;
}

test "t46" {
    assert (bestrelpath('a/b', 'a') == 'b');;
}

test "t47" {
    assert (bestrelpath('a') == 'a');;
}

test "t48" {
    assert (bestrelpath(r'foo\bar', r'C:\foo\bar') == r'foo\bar');;
}

test "t49" {
    assert (bestrelpath('foo', 'foo') == 'foo');;
}

test "t50" {
    assert (bestrelpath('a/b/c', 'a/b') == 'c');;
}

test "t51" {
    assert (bestrelpath('abc', 'abc') == 'abc');;
}

test "t52" {
    assert (bestrelpath('/etc/passwd') == '/etc/passwd');;
}

test "t53" {
    assert (bestrelpath('abc', '.') == 'abc');;
}

test "t54" {
    assert (
        bestrelpath(r'C:\Program Files\Python 3.3\Lib\shutil.py')
        == r'C:\Program Files\Python 3.3\Lib\shutil.py'
    );;
}

test "t55" {
    assert (bestrelpath(r'c:\a', r'b') == r'c:\a');;
}

test "t56" {
    assert (bestrelpath('.', 'foo') == '.');;
}

test "t57" {
    assert (bestrelpath(r'/a', r'c:\b') == r'/a');;
}

test "t58" {
    assert (bestrelpath('foo/bar', 'foo') == 'bar');;
}

test "t59" {
    assert (bestrelpath('foo/../bar.txt', '.') == 'bar.txt');;
}

test "t60" {
    assert (bestrelpath('abc', 'abc/') == 'abc');;
}

test "t61" {
    assert (bestrelpath('foo/bar', 'foo/') == 'bar');;
}

test "t62" {
    assert (bestrelpath(r'foo\bar', r'baz\bar') == r'foo\bar');;
}

test "t63" {
    assert (bestrelpath(r'C:\Users\Foo\bar', r'C:\Users\Baz') == r'C:\Users\Foo\bar');;
}

test "t64" {
    assert (bestrelpath('a', 'a') == 'a');;
}

test "t65" {
    assert (bestrelpath('abc', 'abc/def') == 'abc');;
}

test "t66" {
    assert (
        bestrelpath(r'foo/bar/baz', r'/foo/bar/baz/quux/quux/quux') == r'foo/bar/baz'
    );;
}

test "t67" {
    assert (bestrelpath('abc') == 'abc');;
}

test "t68" {
    assert (bestrelpath('a/b/c') == 'a/b/c');;
}

test "t69" {
    assert (bestrelpath('.', '/bar') == '.');;
}

test "t70" {
    assert (bestrelpath('/foo/bar/', '/foo/') == 'bar');;
}

test "t71" {
    assert (bestrelpath(r'C:\a\b\c') == r'C:\a\b\c');;
}

test "t72" {
    assert (bestrelpath('/foo/bar', '/foo') == 'bar');;
}

test "t73" {
    assert (bestrelpath('../bar') == '../bar');;
}

test "t74" {
    assert (bestrelpath('abc/def', 'ghi/jkl') == 'abc/def');;
}

test "t75" {
    assert (bestrelpath('foo', '/foo') == 'foo');;
}

test "t76" {
    assert (bestrelpath(r'c:\a', r'c:/b') == r'c:\a');;
}

test "t77" {
    assert (bestrelpath(r'foo\bar', r'baz') == r'foo\bar');;
}

test "t78" {
    assert (bestrelpath('foo/bar.txt') == 'foo/bar.txt');;
}

test "t79" {
    assert (bestrelpath('a', '/tmp') == 'a');;
}

test "t80" {
    assert (bestrelpath('abc', 'def') == 'abc');;
}

test "t81" {
    assert (bestrelpath(r'c:/a', r'c:\b') == r'c:/a');;
}

test "t82" {
    assert (bestrelpath('bar.txt', '/foo') == 'bar.txt');;
}

test "t83" {
    assert (bestrelpath(r'foo\bar') == r'foo\bar');;
}

test "t84" {
    assert (
        bestrelpath(r'C:\Users\Foo\bar', r'C:\Users\Foo\baz') == r'C:\Users\Foo\bar'
    );;
}

test "t85" {
    assert (bestrelpath(r'C:\foo\bar', r'foo\bar') == r'C:\foo\bar');;
}

test "t86" {
    assert (bestrelpath(r'foo/bar/baz', r'foo/bar') == r'baz');;
}

test "t87" {
    assert (bestrelpath('foo', 'bar') == 'foo');;
}

test "t88" {
    assert (bestrelpath('foo', None) == 'foo');;
}

test "t89" {
    assert (bestrelpath(r'a', r'b') == r'a');;
}

test "t90" {
    assert (bestrelpath('foo/bar.txt', '/foo') == 'foo/bar.txt');;
}

test "t91" {
    assert (bestrelpath('foo') == 'foo');;
}

test "t92" {
    assert (bestrelpath('/a/b/c', 'a/b/c') == '/a/b/c');;
}

test "t93" {
    assert (bestrelpath('a/b') == 'a/b');;
}

test "t94" {
    assert (bestrelpath('/a/b', '/a') == 'b');;
}

test "t95" {
    assert (bestrelpath('/a', '/tmp') == '/a');;
}

test "t96" {
    assert (bestrelpath(r'C:\foo\bar', r'foo') == r'C:\foo\bar');;
}

test "t97" {
    assert (bestrelpath('foo/') == 'foo');;
}

test "t98" {
    assert (bestrelpath('foo/bar') == 'foo/bar');;
}

test "t99" {
    assert (bestrelpath('bar.txt') == 'bar.txt');;
}

test "t100" {
    assert (bestrelpath('/foo/bar', '/baz') == '/foo/bar');;
}

test "t101" {
    assert (bestrelpath('foo/bar.txt', '.') == 'foo/bar.txt');;
}

test "t102" {
    assert (bestrelpath('foo/../bar.txt') == 'bar.txt');;
}

test "t103" {
    assert (bestrelpath(r'foo/bar/baz', r'/foo') == r'foo/bar/baz');;
}

test "t104" {
    assert (bestrelpath('/foo', 'foo') == '/foo');;
}

test "t105" {
    assert (bestrelpath(r'C:\Users\Foo\bar') == r'C:\Users\Foo\bar');;
}

test "t106" {
    assert (bestrelpath(r'foo/bar/baz', r'/foo/bar/baz/quux') == r'foo/bar/baz');;
}

test "t107" {
    assert (bestrelpath('/foo', 'bar') == '/foo');;
}

test "t108" {
    assert (bestrelpath('a/b', 'a') == 'b');;
}
