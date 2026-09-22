def list2dict(infos):
    """We want a mapping name: char/service for convenience, not a list."""
    info_dict = {}
    for info in infos:
        info_dict[info["Name"]] = info
        del info["Name"]
    return info_dict

assert list2dict([
    {"Name": "Alice", "Age": 20},
    {"Name": "Bob", "Age": 21},
    {"Name": "Bob", "Age": 21},
]) == {
    "Alice": {"Age": 20},
    "Bob": {"Age": 21},
}
assert list2dict(
    [{"Name": "A", "Value": "0"}]
) == {
    "A": {"Value": "0"}
}
assert list2dict(
    [{"Name": "foo", "Char": "bar"}, {"Name": "baz", "Service": "quux"}]
) == {
    "foo": {"Char": "bar"},
    "baz": {"Service": "quux"},
}
assert list2dict(
    [{"Name": "foo", "Value": "bar"}, {"Name": "spam", "Value": "eggs"}]
) == {"foo": {"Value": "bar"}, "spam": {"Value": "eggs"}}
assert list2dict([{"Name": "foo", "Command": "bar"}]) == {"foo": {"Command": "bar"}}
assert list2dict(
    [{"Name": "a", "Char": "b", "Int": 1, "Float": 2.2, "List": [1, 2, 3]}]
) == {
    "a": {"Char": "b", "Int": 1, "Float": 2.2, "List": [1, 2, 3]},
}
assert list2dict(
    [
        {"Name": "foo", "Path": "bar"},
        {"Name": "bar", "Path": "foo", "Active": "baz"},
    ]
) == {"foo": {"Path": "bar"}, "bar": {"Path": "foo", "Active": "baz"}}
assert list2dict(
    [
        {"Name": "Alice", "Age": 20},
        {"Name": "Bob", "Age": 21},
    ],
) == {
    "Alice": {"Age": 20},
    "Bob": {"Age": 21},
}
assert list2dict(
    [
        {"Name": "Alpha", "Value": "A"},
        {"Name": "Beta", "Value": "B"},
        {"Name": "Gamma", "Value": "C"},
    ]
) == {"Alpha": {"Value": "A"}, "Beta": {"Value": "B"}, "Gamma": {"Value": "C"}}
assert list2dict(
    [
        {"Name": "foo", "Path": "bar"},
        {"Name": "bar", "Path": "foo"},
    ]
) == {"foo": {"Path": "bar"}, "bar": {"Path": "foo"}}
assert list2dict(
    [
        {"Name": "abc", "Value": "123"},
        {"Name": "def", "Value": "456"},
        {"Name": "ghi", "Value": "789"},
    ]
) == {
    "abc": {"Value": "123"},
    "def": {"Value": "456"},
    "ghi": {"Value": "789"},
}
assert list2dict(
    [
        {"Name": "foo", "Path": "bar"},
        {"Name": "bar", "Active": "baz"},
    ]
) == {"foo": {"Path": "bar"}, "bar": {"Active": "baz"}}
assert list2dict(
    [
        {"Name": "Foo", "Type": "bar"},
        {"Name": "Baz", "Type": "bazzinga"},
    ]
) == {
    "Foo": {"Type": "bar"},
    "Baz": {"Type": "bazzinga"},
}
assert list2dict([{"Name": "foo", "Char": "bar"}, {"Name": "baz"}]) == {
    "foo": {"Char": "bar"},
    "baz": {},
}
assert list2dict(list()) == {}
assert list2dict(
    [
        {"Name": "foo"},
        {"Name": "bar"},
    ]
) == {"foo": {}, "bar": {}}
assert list2dict([]) == {}
assert list2dict(
    [
        {"Name": "Foo", "Age": 10},
        {"Name": "Bar", "Age": 12},
        {"Name": "Baz", "Age": 14},
    ]
) == {
    "Foo": {"Age": 10},
    "Bar": {"Age": 12},
    "Baz": {"Age": 14},
}
assert list2dict(
    [{"Name": "one", "Value": "1"}, {"Name": "two", "Value": "2"}]
) == {"one": {"Value": "1"}, "two": {"Value": "2"}}
assert list2dict([{"Name": "foo"}, {"Name": "bar"}]) == {"foo": {}, "bar": {}}
assert list2dict([{"Name": "abc"}, {"Name": None}, {"Name": "abc"}]) == {
    "abc": {},
    None: {},
    }
assert list2dict(
    [{"Name": "one", "Value": "1"}, {"Name": "two", "Value": "2"}]
) == {
    "one": {"Value": "1"},
    "two": {"Value": "2"}
}
assert list2dict([{"Name": "abc"}, {"Name": None}, {"Name": "def"}]) == {
    "abc": {},
    None: {},
    "def": {},
    }
assert list2dict([{"Name": "foo"}]) == {"foo": {}}
assert list2dict(
    [
        {"Name": "foo", "Path": "bar", "Active": "baz"},
        {"Name": "bar", "Path": "foo", "Active": "baz"},
    ]
) == {"foo": {"Path": "bar", "Active": "baz"}, "bar": {"Path": "foo", "Active": "baz"}}
assert list2dict(
    [{"Name": "abc", "Color": "blue"},
     {"Name": "def", "Color": "red"}]) == {
    "abc": {"Color": "blue"},
    "def": {"Color": "red"}}
assert list2dict([{"Name": "TestService", "ID": 1}]) == {"TestService": {"ID": 1}}
assert list2dict(
    [{"Name": "A", "Value": "0"}, {"Name": "A", "Value": "1"}, {"Name": "B", "Value": "2"}]
) == {
    "A": {"Value": "1"},
    "B": {"Value": "2"}
}
assert list2dict(
    [
        {
            "Name": "name1",
            "Description": "desc1",
        },
        {
            "Name": "name2",
            "Description": "desc2",
        }
    ]
) == {
        "name1": {
            "Description": "desc1",
        },
        "name2": {
            "Description": "desc2",
        }
}
assert list2dict(
    [{"Name": "foo", "bar": "baz"}, {"Name": "spam", "bar": "eggs"}]
) == {"foo": {"bar": "baz"}, "spam": {"bar": "eggs"}}
assert list2dict([{"Name": "foo", "Char": "bar", "Service": "baz"},
                  {"Name": "foo", "Char": "norf", "Service": "thud"}]) == {
    "foo": {"Char": "norf", "Service": "thud"}
}
assert list2dict(
    [
        {
            "Name": "FOO",
            "Value": "BAR",
        },
        {
            "Name": "BAZ",
            "Value": "QUX",
        },
    ]
) == {"FOO": {"Value": "BAR"}, "BAZ": {"Value": "QUX"}}
assert list2dict(
    [
        {
            "Name": "FOO",
            "Value": "BAR",
        }
    ]
) == {"FOO": {"Value": "BAR"}}
assert list2dict(
    [
        {"Name": "Char", "HP": 100, "MP": 10, "Level": 1},
        {"Name": "Service", "HP": 100, "MP": 10, "Level": 1},
    ]
) == {"Char": {"HP": 100, "MP": 10, "Level": 1}, "Service": {"HP": 100, "MP": 10, "Level": 1}}
assert list2dict(
    [
        {"Name": "e", "Value": "f", "Char": "g", "Service": "h"},
        {"Name": "i", "Value": "j", "Char": "k", "Service": "l"},
        {"Name": "a", "Value": "b", "Char": "c", "Service": "d"},
    ]
) == {
    "a": {"Value": "b", "Char": "c", "Service": "d"},
    "e": {"Value": "f", "Char": "g", "Service": "h"},
    "i": {"Value": "j", "Char": "k", "Service": "l"},
}
assert list2dict([{"Name": "foo", "Command": "bar"}, {"Name": "baz", "Command": "bar"}]) == {"foo": {"Command": "bar"}, "baz": {"Command": "bar"}}
assert list2dict(
    [{"Name": "TestService1", "ID": 1}, {"Name": "TestService2", "ID": 2}]) == {
            "TestService1": {"ID": 1},
            "TestService2": {"ID": 2}
        }
assert list2dict(
    [
        {"Name": "Char", "HP": 100, "MP": 10, "Level": 1},
        {"Name": "Service", "HP": 100, "MP": 10, "Level": 1},
        {"Name": "Service", "HP": 100, "MP": 10, "Level": 1},
    ]
) == {"Char": {"HP": 100, "MP": 10, "Level": 1}, "Service": {"HP": 100, "MP": 10, "Level": 1}}
assert list2dict(
    [
        {
            "Name": "FOO",
            "Value": "BAR",
        },
        {
            "Name": "FOO",
            "Value": "BAZ",
        },
    ]
) == {"FOO": {"Value": "BAZ"}}
assert list2dict([{"Name": "abc"}, {"Name": "def"}]) == {
    "abc": {},
    "def": {},
    }
assert list2dict(
    [
        {"Name": "abc", "Data": "123"},
        {"Name": "def", "Data": "456"},
        {"Name": "ghi", "Data": "789"},
    ]
) == {
    "abc": {"Data": "123"},
    "def": {"Data": "456"},
    "ghi": {"Data": "789"},
}
assert list2dict([{"Name": "foo", "Char": "bar", "Service": "baz"},
                  {"Name": "qux", "Char": "norf", "Service": "thud"}]) == {
    "foo": {"Char": "bar", "Service": "baz"},
    "qux": {"Char": "norf", "Service": "thud"}
}
assert list2dict(
    [{"Name": "A", "Value": "0"}, {"Name": "B", "Value": "1"}]
) == {
    "A": {"Value": "0"},
    "B": {"Value": "1"}
}
assert list2dict(
    [
        {"Name": "Alpha", "Value": "A"},
        {"Name": "Beta", "Value": "B"},
        {"Name": "Alpha", "Value": "C"},
    ]
) == {"Alpha": {"Value": "C"}, "Beta": {"Value": "B"}}
assert list2dict([{"Name": "foo", "Command": "bar"}, {"Name": "baz", "Command": "qux"}]) == {"foo": {"Command": "bar"}, "baz": {"Command": "qux"}}
assert list2dict(
    [{"Name": "A", "Value": "0"}, {"Name": "A", "Value": "1"}]
) == {
    "A": {"Value": "1"}
}
assert list2dict([{"Name": "foo", "Char": "bar", "Service": "baz"}]) == {
    "foo": {"Char": "bar", "Service": "baz"}
}
assert list2dict(
    [
        {"Name": "foo", "Path": "bar", "Active": "baz"},
        {"Name": "bar", "Path": "foo"},
    ]
) == {"foo": {"Path": "bar", "Active": "baz"}, "bar": {"Path": "foo"}}
assert list2dict(
    [
        {"Name": "abc", "Value": "123"},
        {"Name": "def", "Value": "456"},
        {"Name": "ghi", "Value": "789"},
        {"Name": "abc", "Value": "000"},
    ]
) == {
    "abc": {"Value": "000"},
    "def": {"Value": "456"},
    "ghi": {"Value": "789"},
}
assert list2dict(
    [
        {"Name": "a", "Value": "b", "Char": "c", "Service": "d"},
        {"Name": "e", "Value": "f", "Char": "g", "Service": "h"},
        {"Name": "i", "Value": "j", "Char": "k", "Service": "l"}
    ]
) == {
    "a": {"Value": "b", "Char": "c", "Service": "d"},
    "e": {"Value": "f", "Char": "g", "Service": "h"},
    "i": {"Value": "j", "Char": "k", "Service": "l"},
}
