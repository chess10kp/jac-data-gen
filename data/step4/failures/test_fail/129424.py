def find_in_path(filenames):
    """Find file on system path."""
    # http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/52224
    from os.path import exists, join, abspath
    from os import pathsep, environ
    search_path = environ["PATH"]
    paths = search_path.split(pathsep)
    for path in paths:
        for filename in filenames:
            if exists(join(path, filename)):
                return abspath(join(path, filename))

assert find_in_path(
    ["pip-2.7.exe"]) == None
assert find_in_path(
    ["python"]) == "/usr/bin/python"
assert find_in_path(["foo", "bar", "ls"]) == "/bin/ls"
assert find_in_path(["notthere", "/bin/ls", "also_not_there"]) == "/bin/ls"
assert find_in_path(["ls", "cat"]) == "/bin/ls"
assert find_in_path(["foo", "bar"]) == None
assert find_in_path(['python2.7']) == '/usr/bin/python2.7'
assert find_in_path(["/bin/ls", "notthere"]) == "/bin/ls"
assert find_in_path(['python']) == '/usr/bin/python'
assert find_in_path(["/bin/ls"]) == "/bin/ls"
assert find_in_path(["/bin/ls", "/bin/cat", "/usr/bin/cat", "notthere"]) == "/bin/ls"
assert find_in_path(["cat"]) == "/bin/cat"
assert find_in_path(["/bin/ls", "/bin/cat", "/usr/bin/cat"]) == "/bin/ls"
assert find_in_path(["/bin/ls", "also_not_there", "notthere"]) == "/bin/ls"
assert find_in_path(["foo"]) == None
assert find_in_path(["notthere", "/bin/ls"]) == "/bin/ls"
assert find_in_path(["ls", "ls"]) == "/bin/ls"
assert find_in_path(["ls"]) == "/bin/ls"
assert find_in_path(
    ["pip-2.7.py"]) == None
assert find_in_path(['python2']) == '/usr/bin/python2'
assert find_in_path(["/bin/ls", "/bin/cat"]) == "/bin/ls"
assert find_in_path(
    [
        'ls',
        'python',
        'python2',
        'python2.7',
    ]
) == '/usr/bin/python'
