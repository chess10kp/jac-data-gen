"""
    Return a string stripped from some leading and trailing punctuations.
    """
def strip_some_punct(s: Any) -> object {
    if s {
        s = s.strip(''','"}{-_:;&''');
        s = s.lstrip('.>)]');
        s = s.rstrip('<([');
    }
    return s;
}

test "t0" {
    assert (strip_some_punct('Hello World!') == 'Hello World!');;
}

test "t1" {
    assert (strip_some_punct('Hello world') == 'Hello world');;
}

test "t2" {
    assert (strip_some_punct('hello: world') == 'hello: world');;
}

test "t3" {
    assert (strip_some_punct('hello:') == 'hello');;
}

test "t4" {
    assert (strip_some_punct('hi') == 'hi');;
}

test "t5" {
    assert (strip_some_punct(',hi,') == 'hi');;
}

test "t6" {
    assert (strip_some_punct('Hello, World') == 'Hello, World');;
}

test "t7" {
    assert (strip_some_punct('hi.') == 'hi.');;
}

test "t8" {
    assert (strip_some_punct('hello" world') == 'hello" world');;
}

test "t9" {
    assert (strip_some_punct('hi,') == 'hi');;
}

test "t10" {
    assert (strip_some_punct('hi-_:;&') == 'hi');;
}

test "t11" {
    assert (strip_some_punct('''''') == '');;
}

test "t12" {
    assert (strip_some_punct('abc"def"ghi') == 'abc"def"ghi');;
}

test "t13" {
    assert (strip_some_punct('hi?') == 'hi?');;
}

test "t14" {
    assert (strip_some_punct('hi.') == 'hi.');;
}

test "t15" {
    assert (strip_some_punct('hi~') == 'hi~');;
}

test "t16" {
    assert (strip_some_punct('hello" world.?"') == 'hello" world.?');;
}

test "t17" {
    assert (strip_some_punct('""abc"def"') == 'abc"def');;
}

test "t18" {
    assert (strip_some_punct('hello world') == 'hello world');;
}

test "t19" {
    assert (strip_some_punct('hello') == 'hello');;
}

test "t20" {
    assert (strip_some_punct('hello;') == 'hello');;
}

test "t21" {
    assert (strip_some_punct('abc"def"ghi"jkl"mno') == 'abc"def"ghi"jkl"mno');;
}

test "t22" {
    assert (strip_some_punct('Hello, world!') == 'Hello, world!');;
}

test "t23" {
    assert (strip_some_punct('abc') == 'abc');;
}

test "t24" {
    assert (strip_some_punct('hi"') == 'hi');;
}

test "t25" {
    assert (strip_some_punct('hi_') == 'hi');;
}

test "t26" {
    assert (strip_some_punct('hello:') == 'hello');;
}

test "t27" {
    assert (strip_some_punct('hi)') == 'hi)');
    assert (strip_some_punct('hi{') == 'hi');
    assert (strip_some_punct('abcdef') == 'abcdef');
    assert (strip_some_punct('') == '');
    assert (strip_some_punct('"hi"') == 'hi');
    assert (strip_some_punct('"') == '');
    assert (strip_some_punct('abc"def"ghi"jkl"mno"pqr') == 'abc"def"ghi"jkl"mno"pqr');
    assert (strip_some_punct('hello') == 'hello');
    assert (strip_some_punct('hello? world') == 'hello? world');
    assert (strip_some_punct('hello,') == 'hello');
    assert (strip_some_punct(None) == None);
    assert (strip_some_punct('Hello, World.') == 'Hello, World.');
    assert (strip_some_punct('hello:') == 'hello');
    assert (strip_some_punct('""') == '');
    assert (strip_some_punct('"') == '');
    assert (strip_some_punct('a!b') == 'a!b');
    assert (strip_some_punct('hi(') == 'hi');
    assert (strip_some_punct('""abc"def""') == 'abc"def');
    assert (strip_some_punct('hi') == 'hi');
    assert (strip_some_punct('hi>') == 'hi>');
    assert (strip_some_punct('"') == '');
    assert (strip_some_punct('hello,') == 'hello');
    assert (strip_some_punct('hello,') == 'hello');
    assert (strip_some_punct('hi') == 'hi');
    assert (strip_some_punct('hello! world') == 'hello! world');
    assert (strip_some_punct('hello') == 'hello');
    assert (strip_some_punct('hi;') == 'hi');
    assert (strip_some_punct('hi}') == 'hi');
    assert (strip_some_punct('hello" world?!"') == 'hello" world?!');
    assert (strip_some_punct('Hello World') == 'Hello World');
    assert (strip_some_punct('a') == 'a');
    assert (strip_some_punct('hello. world') == 'hello. world');
    assert (strip_some_punct('..hello') == 'hello');
    assert (strip_some_punct("'''") == '');
    assert (strip_some_punct('') == '');
    assert (strip_some_punct('''I'm not sure...''') == '''I'm not sure...''');
    assert (strip_some_punct('hello') == 'hello');
    assert (strip_some_punct('hi/') == 'hi/');
    assert (strip_some_punct('"<NAME>"') == '<NAME>');
    assert (strip_some_punct('hi:') == 'hi');
    assert (strip_some_punct('hi\\') == 'hi\\');
    assert (strip_some_punct("Hello, world!") == 'Hello, world!');
    assert (strip_some_punct('a?b') == 'a?b');
    assert (strip_some_punct('hi]') == 'hi]');
    assert (strip_some_punct('hello') == 'hello');
    assert (strip_some_punct('hello;') == 'hello');
    assert (strip_some_punct('Hello') == 'Hello');
    assert (strip_some_punct('hello" world!"') == 'hello" world!');
    assert (strip_some_punct('hello') == 'hello');
    assert (strip_some_punct('(hi, "hi")') == '(hi, "hi")');
    assert (strip_some_punct('hi&') == 'hi');
    assert (strip_some_punct('hi-') == 'hi');
    assert (strip_some_punct('hi!') == 'hi!');
    assert (strip_some_punct('hi') == 'hi');
    assert (strip_some_punct('hello, world') == 'hello, world');
    assert (strip_some_punct('hello" world"') == 'hello" world');
    assert (strip_some_punct('a;b') == 'a;;
}

test "t28" {
    b');
    assert (strip_some_punct('"""') == '');
    assert (strip_some_punct('hello" world?"') == 'hello" world?');
    assert (strip_some_punct('hello" world.!"') == 'hello" world.!');
    assert (strip_some_punct('hello;') == 'hello');
    assert (strip_some_punct('abc"def') == 'abc"def');
    assert (strip_some_punct("''") == '');
    assert (strip_some_punct('hello; world') == 'hello;;
}

test "t29" {
    world');
    assert (strip_some_punct('Hello, World!') == 'Hello, World!');
    assert (strip_some_punct('abc>') == 'abc>');
    assert (strip_some_punct('Hello. World.') == 'Hello. World.');
    assert (strip_some_punct('[hi, "hi"]') == '[hi, "hi"]');
    assert (strip_some_punct('.hello') == 'hello');
    assert (strip_some_punct('hello') == 'hello');
    assert (strip_some_punct('') == '');
    assert (strip_some_punct('a.b') == 'a.b');
    assert (strip_some_punct('hi<') == 'hi');
    assert (strip_some_punct('Hello World.') == 'Hello World.');
    assert (strip_some_punct('a:b') == 'a:b');
    assert (strip_some_punct('"') == '');;
}
