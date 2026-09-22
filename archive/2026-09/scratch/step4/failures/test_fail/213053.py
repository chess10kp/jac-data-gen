def ensure_path(path):
    """ Check if a path exists. If not, create the necessary directories, 
    but if the path includes a file, don't create the file"""
    import os, errno
    dir_path = os.path.dirname(path)
    if len(dir_path) > 0:  # Only run makedirs if there is a directory to create!
        try:
            os.makedirs(dir_path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise
    return path

assert ensure_path(
    "./a/b/c.d"
) == "./a/b/c.d"
assert ensure_path('.foo/bar/') == '.foo/bar/'
assert ensure_path("/home/student") == "/home/student"
assert ensure_path(
    "/a/b/c/d"
) == "/a/b/c/d"
assert ensure_path('/foo/bar') == '/foo/bar'
assert ensure_path(r'/home') == r'/home'
assert ensure_path(
    "/home/user/testing/test1/test2/test3/test4") == "/home/user/testing/test1/test2/test3/test4"
assert ensure_path(
    "./a/b/c/d.e"
) == "./a/b/c/d.e"
assert ensure_path(b"") == b""
assert ensure_path(r"C:\Python\dir1\dir2\dir3\file.txt") == r"C:\Python\dir1\dir2\dir3\file.txt"
assert ensure_path("foo.txt") == "foo.txt"
assert ensure_path("abc") == "abc"
assert ensure_path("/home") == "/home"
assert ensure_path(r"C:\Python\dir1\dir2\sample.txt") == r"C:\Python\dir1\dir2\sample.txt"
assert ensure_path('path_4/path_5/path_6/path_7/file_1') == 'path_4/path_5/path_6/path_7/file_1'
assert ensure_path(
    "/home/student/directory/file.txt") == "/home/student/directory/file.txt"
assert ensure_path("/home/users/a/b/c/d.txt") == "/home/users/a/b/c/d.txt"
assert ensure_path(r"C:\temp\newfile\newdir") == r"C:\temp\newfile\newdir"
assert ensure_path(r'/home/student') == r'/home/student'
assert ensure_path(r'') == r''
assert ensure_path("abc/def") == "abc/def"
assert ensure_path(
    "./a/b/c/d"
) == "./a/b/c/d"
assert ensure_path(r'foo/bar/foo.txt.bak') == r'foo/bar/foo.txt.bak'
assert ensure_path(r'foo/bar/foo.txt') == r'foo/bar/foo.txt'
assert ensure_path("abc") == "abc"
assert ensure_path('tmp/a.py') == 'tmp/a.py'
assert ensure_path('http://some-url.com/tmp/a/b.py') == 'http://some-url.com/tmp/a/b.py'
assert ensure_path(
    "/a/b/c/"
) == "/a/b/c/"
assert ensure_path('/') == '/'
assert ensure_path(r"C:\temp\newdir\newdir2\newdir3\newdir4") == r"C:\temp\newdir\newdir2\newdir3\newdir4"
assert ensure_path(
    "/c/d"
) == "/c/d"
assert ensure_path(
    "/c"
) == "/c"
assert ensure_path(r"C:\Python\dir1\dir2\sample") == r"C:\Python\dir1\dir2\sample"
assert ensure_path("") == ""
assert ensure_path(
    "./a/b/c/"
) == "./a/b/c/"
assert ensure_path(
    "c/d"
) == "c/d"
assert ensure_path(r'foo/bar') == r'foo/bar'
assert ensure_path(r"C:\temp\newdir\newdir2\newfile") == r"C:\temp\newdir\newdir2\newfile"
assert ensure_path(r"C:\Python\sample") == r"C:\Python\sample"
assert ensure_path("/home/student/directory/file.txt") == "/home/student/directory/file.txt"
assert ensure_path("foo/bar/baz/quux") == "foo/bar/baz/quux"
assert ensure_path(b"abc/def/ghi") == b"abc/def/ghi"
assert ensure_path(
    "./a/b/c"
) == "./a/b/c"
assert ensure_path(r"C:\temp\newfile\newdir\newfile") == r"C:\temp\newfile\newdir\newfile"
assert ensure_path(
    "/a/b/c.d"
) == "/a/b/c.d"
assert ensure_path("./tests/output/ensure_path/new_directory/test_file.txt") == "./tests/output/ensure_path/new_directory/test_file.txt"
assert ensure_path(b"abc") == b"abc"
assert ensure_path(r"C:\myfolder\myfile.txt") == r"C:\myfolder\myfile.txt"
assert ensure_path('http://some-url.com/tmp/a/b') == 'http://some-url.com/tmp/a/b'
assert ensure_path(
    "/Users/lpritam/Documents/workspace/projects/learning-python/python_crash_course/project_7_oop/test.txt"
) == "/Users/lpritam/Documents/workspace/projects/learning-python/python_crash_course/project_7_oop/test.txt"
assert ensure_path(
    "c/"
) == "c/"
assert ensure_path(r'/home/student/foo.txt.bak') == r'/home/student/foo.txt.bak'
assert ensure_path(r"C:\temp\newfile\newfile\newfile") == r"C:\temp\newfile\newfile\newfile"
assert ensure_path('.foo/.bar/baz.txt') == '.foo/.bar/baz.txt'
assert ensure_path(r'/') == r'/'
assert ensure_path(
    "c.d"
) == "c.d"
assert ensure_path(
    "/c.d"
) == "/c.d"
assert ensure_path(b"abc/def") == b"abc/def"
assert ensure_path('foo/bar/baz.txt') == 'foo/bar/baz.txt'
assert ensure_path(
    "./a/b/c.d/"
) == "./a/b/c.d/"
assert ensure_path("foo/bar") == "foo/bar"
assert ensure_path("/Users/lpritam/Documents/workspace/projects/learning-python/python_crash_course/project_7_oop") == "/Users/lpritam/Documents/workspace/projects/learning-python/python_crash_course/project_7_oop"
assert ensure_path(r"C:\Python\dir1\dir2\dir3") == r"C:\Python\dir1\dir2\dir3"
assert ensure_path("abc/def/ghi") == "abc/def/ghi"
assert ensure_path(r'/home/student/foo.txt') == r'/home/student/foo.txt'
assert ensure_path("abc/def") == "abc/def"
assert ensure_path('foo/bar/baz') == 'foo/bar/baz'
assert ensure_path('/foo/bar/') == '/foo/bar/'
assert ensure_path(r"C:\myfolder") == r"C:\myfolder"
assert ensure_path('.foo/.bar/') == '.foo/.bar/'
assert ensure_path('') == ''
assert ensure_path('path_4') == 'path_4'
assert ensure_path(r"C:\temp\newfile\newfile\newfile\newdir") == r"C:\temp\newfile\newfile\newfile\newdir"
assert ensure_path('.') == '.'
assert ensure_path(
    "/home/user/testing/test1/test2/test3/test4/test5.txt") == "/home/user/testing/test1/test2/test3/test4/test5.txt"
assert ensure_path("") == ""
assert ensure_path(r"C:\temp\newfile\newfile") == r"C:\temp\newfile\newfile"
assert ensure_path(r'foo.txt') == r'foo.txt'
assert ensure_path(r"C:\Python\dir1\dir2\file.txt") == r"C:\Python\dir1\dir2\file.txt"
assert ensure_path(r"C:\temp\newdir\newdir2") == r"C:\temp\newdir\newdir2"
assert ensure_path(r"C:\temp\newfile") == r"C:\temp\newfile"
assert ensure_path("/home/student/directory") == "/home/student/directory"
assert ensure_path(r"C:\Python\sample.txt") == r"C:\Python\sample.txt"
assert ensure_path(
    "./a/b/c/d/"
) == "./a/b/c/d/"
assert ensure_path("foo/bar/baz") == "foo/bar/baz"
assert ensure_path("/home/users/a/b/c/d.txt/") == "/home/users/a/b/c/d.txt/"
assert ensure_path(r"C:\users\me\data\test.txt") == r"C:\users\me\data\test.txt"
assert ensure_path('foo/bar') == 'foo/bar'
assert ensure_path("/Users/lpritam/Documents/workspace/projects/learning-python/python_crash_course/project_7_oop/") == "/Users/lpritam/Documents/workspace/projects/learning-python/python_crash_course/project_7_oop/"
assert ensure_path(r"C:\Python\dir1\dir2") == r"C:\Python\dir1\dir2"
assert ensure_path("abc/def/ghi") == "abc/def/ghi"
assert ensure_path('http://some-url.com/tmp/a') == 'http://some-url.com/tmp/a'
assert ensure_path(
    "./tests/output/ensure_path/basic_test.txt"
) == "./tests/output/ensure_path/basic_test.txt"
