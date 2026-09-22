def parse_envs(arg):
    """Parse environment configs as a dict.

    Support format 'k1=v1,k2=v2,k3=v3..'. Note that comma is supported
    in value field.
    """
    envs = {}
    if not arg:
        return envs

    i = 0
    fields = arg.split("=")
    if len(fields) < 2:
        return envs
    pre_key = ""
    while i < len(fields):
        if i == 0:
            pre_key = fields[i]
        elif i == len(fields) - 1:
            envs[pre_key] = fields[i]
        else:
            r = fields[i].rfind(",")
            envs[pre_key] = fields[i][:r]
            pre_key = fields[i][r + 1 :]  # noqa: E203
        i += 1
    return envs

assert parse_envs("key") == {}
assert parse_envs("k1=v1,,") == {"k1": "v1,,"}
assert parse_envs("a=1") == {"a": "1"}
assert parse_envs("x=y,z=z") == {"x": "y", "z": "z"}
assert parse_envs("a=a,b=b,c=c,d=d,e=e") == {"a": "a", "b": "b", "c": "c", "d": "d", "e": "e"}
assert parse_envs("A=B,C=D,E=F,G=H") == {"A": "B", "C": "D", "E": "F", "G": "H"}
assert parse_envs("foo=bar") == {"foo": "bar"}
assert parse_envs("k1=v1") == {"k1": "v1"}
assert parse_envs("key=value,key1=value1,key2=value2") == {
    "key": "value",
    "key1": "value1",
    "key2": "value2",
}
assert parse_envs("key=value") == {"key": "value"}
assert parse_envs("a=") == {"a": ""}
assert parse_envs("a=1,b=2,c=3,d=a,b,c") == {
    "a": "1",
    "b": "2",
    "c": "3",
    "d": "a,b,c",
}
assert parse_envs("key=value1,value2") == {"key": "value1,value2"}
assert parse_envs(
    "k1=v1,k2=v2,k3="
) == {"k1": "v1", "k2": "v2", "k3": ""}
assert parse_envs("key1=") == {"key1": ""}
assert parse_envs("a=1,b=2") == {"a": "1", "b": "2"}
assert parse_envs("a=b,c=d,e=f,g=h") == {"a": "b", "c": "d", "e": "f", "g": "h"}
assert parse_envs("foo=bar,baz=qux,quux=corge") == {"foo": "bar", "baz": "qux", "quux": "corge"}
assert parse_envs(" a ") == {}
assert parse_envs("abc") == {}
assert parse_envs("") == {}
assert parse_envs("key1=value1,key2=value2") == {"key1": "value1", "key2": "value2"}
assert parse_envs("A=B,C=D,E=F,G=H,I=J,K=L,M=N") == {"A": "B", "C": "D", "E": "F", "G": "H", "I": "J", "K": "L", "M": "N"}
assert parse_envs(" ") == {}
assert parse_envs("A=B") == {"A": "B"}
assert parse_envs("a=a,b=b,c=c,d=d") == {"a": "a", "b": "b", "c": "c", "d": "d"}
assert parse_envs("A=B,C=D,E=F,G=H,I=J,K=L,M=N,O=P") == {"A": "B", "C": "D", "E": "F", "G": "H", "I": "J", "K": "L", "M": "N", "O": "P"}
assert parse_envs("a=b") == {'a': 'b'}
assert parse_envs(" a b ") == {}
assert parse_envs("A=B,C=D") == {"A": "B", "C": "D"}
assert parse_envs("key=value,key2=value2") == {"key": "value", "key2": "value2"}
assert parse_envs("a=b,c=d,e=f") == {"a": "b", "c": "d", "e": "f"}
assert parse_envs("a=a") == {"a": "a"}
assert parse_envs("a=b,c=d,e=f,g=h,i=j,k=l,m=n") == {
    "a": "b",
    "c": "d",
    "e": "f",
    "g": "h",
    "i": "j",
    "k": "l",
    "m": "n",
}
assert parse_envs("A=B,C=D,E=F") == {"A": "B", "C": "D", "E": "F"}
assert parse_envs("hello=world") == {"hello": "world"}
assert parse_envs("a=a,b=b") == {"a": "a", "b": "b"}
assert parse_envs("A=B,C=D,E=F,G=H,I=J") == {"A": "B", "C": "D", "E": "F", "G": "H", "I": "J"}
assert parse_envs(
    "k1=v1,k2=v2,k3=v3"
) == {"k1": "v1", "k2": "v2", "k3": "v3"}
assert parse_envs("k1=v1,k2=v2,k3=v3") == {"k1": "v1", "k2": "v2", "k3": "v3"}
assert parse_envs(
    "k1=,k2=v3"
) == {"k1": "", "k2": "v3"}
assert parse_envs("key1=value1") == {"key1": "value1"}
assert parse_envs("a=a,b=b,c=c") == {"a": "a", "b": "b", "c": "c"}
assert parse_envs("key=value,key2=value2,key3=value3") == {"key": "value", "key2": "value2", "key3": "value3"}
assert parse_envs("k1=v1,k2=v2,k3=v3,k4=v4") == {
    "k1": "v1",
    "k2": "v2",
    "k3": "v3",
    "k4": "v4",
}
assert parse_envs("k1=v1,k2=v2") == {"k1": "v1", "k2": "v2"}
assert parse_envs(" a b c ") == {}
assert parse_envs("a=b,c=d,e=f,g=h,i=j,k=l,m=n,o=p,q=r,s=t,u=v,w=x,y=z") == {
    "a": "b",
    "c": "d",
    "e": "f",
    "g": "h",
    "i": "j",
    "k": "l",
    "m": "n",
    "o": "p",
    "q": "r",
    "s": "t",
    "": "v",
    "w": "x",
    "y": "z",
}
assert parse_envs("a=b") == {"a": "b"}
assert parse_envs("x=y") == {"x": "y"}
assert parse_envs(None) == {}
assert parse_envs("k1=v1,k2=v2,k3=v3,k4=v4,k5=v5") == {
    "k1": "v1",
    "k2": "v2",
    "k3": "v3",
    "k4": "v4",
    "k5": "v5",
}
assert parse_envs("a=b,c=d,e=f,g=h,i=j") == {"a": "b", "c": "d", "e": "f", "g": "h", "i": "j"}
assert parse_envs("a=1,b=2,c=3") == {"a": "1", "b": "2", "c": "3"}
assert parse_envs("a=b,c=d") == {"a": "b", "c": "d"}
assert parse_envs(
    "k1=,k2="
) == {"k1": "", "k2": ""}
assert parse_envs("hello") == {}
assert parse_envs("hello=world,foo=bar,baz=qux") == {"hello": "world", "foo": "bar", "baz": "qux"}
