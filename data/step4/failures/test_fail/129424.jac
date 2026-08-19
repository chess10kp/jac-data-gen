"""Find file on system path."""
def find_in_path(filenames: Any) -> object {
    import from os.path { exists, join, abspath }
    import from os { pathsep, environ }
    search_path = environ["PATH"];
    paths = search_path.split(pathsep);
    for path in paths {
        for filename in filenames {
            if exists(join(path, filename)) {
                return abspath(join(path, filename));
            }
        }
    }
}

test "t0" {
    assert (find_in_path(["pip-2.7.exe"]) == None);;
}

test "t1" {
    assert (find_in_path(["python"]) == "/usr/bin/python");;
}

test "t2" {
    assert (find_in_path(["foo", "bar", "ls"]) == "/bin/ls");;
}

test "t3" {
    assert (find_in_path(["notthere", "/bin/ls", "also_not_there"]) == "/bin/ls");;
}

test "t4" {
    assert (find_in_path(["ls", "cat"]) == "/bin/ls");;
}

test "t5" {
    assert (find_in_path(["foo", "bar"]) == None);;
}

test "t6" {
    assert (find_in_path(['python2.7']) == '/usr/bin/python2.7');;
}

test "t7" {
    assert (find_in_path(["/bin/ls", "notthere"]) == "/bin/ls");;
}

test "t8" {
    assert (find_in_path(['python']) == '/usr/bin/python');;
}

test "t9" {
    assert (find_in_path(["/bin/ls"]) == "/bin/ls");;
}

test "t10" {
    assert (
        find_in_path(["/bin/ls", "/bin/cat", "/usr/bin/cat", "notthere"]) == "/bin/ls"
    );;
}

test "t11" {
    assert (find_in_path(["cat"]) == "/bin/cat");;
}

test "t12" {
    assert (find_in_path(["/bin/ls", "/bin/cat", "/usr/bin/cat"]) == "/bin/ls");;
}

test "t13" {
    assert (find_in_path(["/bin/ls", "also_not_there", "notthere"]) == "/bin/ls");;
}

test "t14" {
    assert (find_in_path(["foo"]) == None);;
}

test "t15" {
    assert (find_in_path(["notthere", "/bin/ls"]) == "/bin/ls");;
}

test "t16" {
    assert (find_in_path(["ls", "ls"]) == "/bin/ls");;
}

test "t17" {
    assert (find_in_path(["ls"]) == "/bin/ls");;
}

test "t18" {
    assert (find_in_path(["pip-2.7.py"]) == None);;
}

test "t19" {
    assert (find_in_path(['python2']) == '/usr/bin/python2');;
}

test "t20" {
    assert (find_in_path(["/bin/ls", "/bin/cat"]) == "/bin/ls");;
}

test "t21" {
    assert (
        find_in_path(['ls', 'python', 'python2', 'python2.7']) == '/usr/bin/python'
    );;
}
