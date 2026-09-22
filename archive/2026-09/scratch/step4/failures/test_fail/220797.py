def parse_properties(properties):
    """
    Return a dictionary of attributes based on properties.
    Convert properties of form "property1=value1,property2=value2, ..."
    to {'property1': value1, 'property2': value2, ...}.
    """
    pairs = [
        (k.strip(), eval(v.strip()))
        for k, v in
        [prop.split('=', 1) for prop in properties.split(',')]
    ]

    attrs = dict()
    for k, v in pairs:
        if k in attrs:
            if not isinstance(attrs[k], list):
                attrs[k] = [attrs[k]]
            attrs[k].append(v)
        else:
            attrs[k] = v

    return attrs

assert parse_properties(
    'attr1=1,attr2=2,attr3=3'
) == {
    'attr1': 1,
    'attr2': 2,
    'attr3': 3
}
assert parse_properties(
    "x=1,y=2,z=3"
) == {'x': 1, 'y': 2, 'z': 3}
assert parse_properties(
    "a=1"
) == {'a': 1}
assert parse_properties(
    'test=1, test2=2, test3=3, test4=4, test5=5'
) == {'test': 1, 'test2': 2, 'test3': 3, 'test4': 4, 'test5': 5}
assert parse_properties(
    "a=1,b=2,c=3,a=4,a=5,b=6,c=7,a=8,a=9,b=10,c=11,a=12,a=13,b=14,c=15"
) == {
    'a': [1, 4, 5, 8, 9, 12, 13],
    'b': [2, 6, 10, 14],
    'c': [3, 7, 11, 15]
}
assert parse_properties(
    "a=1,b=2,c=3"
) == {'a': 1, 'b': 2, 'c': 3}
assert parse_properties(
    "foo=1,bar=2,baz=3") == {'foo': 1, 'bar': 2, 'baz': 3}
assert parse_properties(
    'a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8, i=9, j=10, k=11, l=12, m=13, n=14, o=15, p=16, q=17, r=18, s=19, t=20, u=21, v=22, w=23, x=24, y=25, z=26') == {
    'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5, 'f': 6, 'g': 7, 'h': 8, 'i': 9, 'j': 10, 'k': 11, 'l': 12,'m': 13, 'n': 14, 'o': 15, 'p': 16, 'q': 17, 'r': 18,'s': 19, 't': 20, '': 21, 'v': 22, 'w': 23, 'x': 24, 'y': 25, 'z': 26}
assert parse_properties('properties={"foo":"bar"}') == {
    'properties': {
        'foo': 'bar'
    }
}
assert parse_properties(
    'attr1=1,attr2=2,attr3=3,attr4=4,attr5=5'
) == {
    'attr1': 1,
    'attr2': 2,
    'attr3': 3,
    'attr4': 4,
    'attr5': 5
}
assert parse_properties(
    'a=1,b=2,c=3,d=4,e=5') == {
        'a': 1,
        'b': 2,
        'c': 3,
        'd': 4,
        'e': 5,
    }
assert parse_properties(
    'attr1=1,attr2=2,attr3=3,attr4=4,attr5=5,attr6=6'
) == {
    'attr1': 1,
    'attr2': 2,
    'attr3': 3,
    'attr4': 4,
    'attr5': 5,
    'attr6': 6
}
assert parse_properties("foo=1") == {'foo': 1}
assert parse_properties(
    'attr1=1,attr2=2,attr3=3,attr4=4,attr5=5,attr6=6,attr7=7'
) == {
    'attr1': 1,
    'attr2': 2,
    'attr3': 3,
    'attr4': 4,
    'attr5': 5,
    'attr6': 6,
    'attr7': 7
}
assert parse_properties(
    "a=1,b=2,c=3,a=4,a=5,b=6,c=7,a=8,a=9,b=10,c=11"
) == {
    'a': [1, 4, 5, 8, 9],
    'b': [2, 6, 10],
    'c': [3, 7, 11]
}
assert parse_properties(
    "a=1,b=2,c=3,d=4,e=5,f=6"
) == {'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5, 'f': 6}
assert parse_properties(
    "a=1,b=2"
) == {'a': 1, 'b': 2}
assert parse_properties(
    'a=1,b=2'
) == {
    'a': 1,
    'b': 2,
}
assert parse_properties(
    "a=1,b=2,c=3,a=4,a=5,b=6,c=7,a=8,a=9,b=10,c=11,a=12"
) == {
    'a': [1, 4, 5, 8, 9, 12],
    'b': [2, 6, 10],
    'c': [3, 7, 11]
}
assert parse_properties(
    'a=1,b=2'
) == {'a': 1, 'b': 2}
assert parse_properties(
    'a=1,b=2,c=3'
) == {
    'a': 1,
    'b': 2,
    'c': 3,
}
assert parse_properties(
    'attr1=1,attr2=2,attr3=3,attr4=4'
) == {
    'attr1': 1,
    'attr2': 2,
    'attr3': 3,
    'attr4': 4
}
