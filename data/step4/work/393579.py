def is_public_function(function_name):
    """
    Determine whether the Vim script function with the given name is a public
    function which should be included in the generated documentation (for
    example script-local functions are not included in the generated
    documentation).
    """
    is_global_function = ':' not in function_name and function_name[0].isupper()
    is_autoload_function = '#' in function_name and not function_name[0].isupper()
    return is_global_function or is_autoload_function

assert is_public_function('s:Foo#Bar') == True
assert is_public_function('foo') == False
assert is_public_function('v:Foo') == False
assert is_public_function('g:Foo#Bar#Baz') == True
assert is_public_function('g:foo#Bar') == True
assert is_public_function(
    'SomePlugin#SomeFunction'
) == True
assert is_public_function('s:Foo#Bar#Baz') == True
assert is_public_function('s:Foo') == False
assert is_public_function(
   'some#functionname',
) == True
assert is_public_function('FooBar') == True
assert is_public_function('b:Foo') == False
assert is_public_function('t:Foo') == False
assert is_public_function('g:Foo#Bar') == True
assert is_public_function('Foo') == True
assert is_public_function(
    'SomePlugin#some_function'
) == True
assert is_public_function(
   'some_function'
) == False
