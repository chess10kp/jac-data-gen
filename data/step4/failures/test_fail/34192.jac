"""Parse environment configs as a dict.

    Support format 'k1=v1,k2=v2,k3=v3..'. Note that comma is supported
    in value field.
    """
def parse_envs(arg: Any) -> object {
    envs = {};
    if not arg {
        return envs;
    }
    i = 0;
    fields = arg.split("=");
    if (len(fields) < 2) {
        return envs;
    }
    pre_key = "";
    while (i < len(fields)) {
        if (i == 0) {
            pre_key = fields[i];
        } elif (i == (len(fields) - 1)) {
            envs[pre_key] = fields[i];
        } else {
            r = fields[i].rfind(",");
            envs[pre_key] = fields[i][:r];
            pre_key = fields[i][(r + 1):];
        }
        i += 1;
    }
    return envs;
}

test "t0" {
    assert (parse_envs("key") == {});;
}

test "t1" {
    assert (parse_envs("k1=v1,,") == {"k1": "v1,,"});;
}

test "t2" {
    assert (parse_envs("a=1") == {"a": "1"});;
}

test "t3" {
    assert (parse_envs("x=y,z=z") == {"x": "y", "z": "z"});;
}

test "t4" {
    assert (
        parse_envs("a=a,b=b,c=c,d=d,e=e")
        == {"a": "a", "b": "b", "c": "c", "d": "d", "e": "e"}
    );;
}

test "t5" {
    assert (parse_envs("A=B,C=D,E=F,G=H") == {"A": "B", "C": "D", "E": "F", "G": "H"});;
}

test "t6" {
    assert (parse_envs("foo=bar") == {"foo": "bar"});;
}

test "t7" {
    assert (parse_envs("k1=v1") == {"k1": "v1"});;
}

test "t8" {
    assert (
        parse_envs("key=value,key1=value1,key2=value2")
        == {"key": "value", "key1": "value1", "key2": "value2"}
    );;
}

test "t9" {
    assert (parse_envs("key=value") == {"key": "value"});;
}

test "t10" {
    assert (parse_envs("a=") == {"a": ""});;
}

test "t11" {
    assert (
        parse_envs("a=1,b=2,c=3,d=a,b,c")
        == {"a": "1", "b": "2", "c": "3", "d": "a,b,c"}
    );;
}

test "t12" {
    assert (parse_envs("key=value1,value2") == {"key": "value1,value2"});;
}

test "t13" {
    assert (parse_envs("k1=v1,k2=v2,k3=") == {"k1": "v1", "k2": "v2", "k3": ""});;
}

test "t14" {
    assert (parse_envs("key1=") == {"key1": ""});;
}

test "t15" {
    assert (parse_envs("a=1,b=2") == {"a": "1", "b": "2"});;
}

test "t16" {
    assert (parse_envs("a=b,c=d,e=f,g=h") == {"a": "b", "c": "d", "e": "f", "g": "h"});;
}

test "t17" {
    assert (
        parse_envs("foo=bar,baz=qux,quux=corge")
        == {"foo": "bar", "baz": "qux", "quux": "corge"}
    );;
}

test "t18" {
    assert (parse_envs(" a ") == {});;
}

test "t19" {
    assert (parse_envs("abc") == {});;
}

test "t20" {
    assert (parse_envs("") == {});;
}

test "t21" {
    assert (
        parse_envs("key1=value1,key2=value2") == {"key1": "value1", "key2": "value2"}
    );;
}

test "t22" {
    assert (
        parse_envs("A=B,C=D,E=F,G=H,I=J,K=L,M=N")
        == {"A": "B", "C": "D", "E": "F", "G": "H", "I": "J", "K": "L", "M": "N"}
    );;
}

test "t23" {
    assert (parse_envs(" ") == {});;
}

test "t24" {
    assert (parse_envs("A=B") == {"A": "B"});;
}

test "t25" {
    assert (parse_envs("a=a,b=b,c=c,d=d") == {"a": "a", "b": "b", "c": "c", "d": "d"});;
}

test "t26" {
    assert (
        parse_envs("A=B,C=D,E=F,G=H,I=J,K=L,M=N,O=P")
        == {
            "A": "B",
            "C": "D",
            "E": "F",
            "G": "H",
            "I": "J",
            "K": "L",
            "M": "N",
            "O": "P"
        }
    );;
}

test "t27" {
    assert (parse_envs("a=b") == {'a': 'b'});;
}

test "t28" {
    assert (parse_envs(" a b ") == {});;
}

test "t29" {
    assert (parse_envs("A=B,C=D") == {"A": "B", "C": "D"});;
}

test "t30" {
    assert (parse_envs("key=value,key2=value2") == {"key": "value", "key2": "value2"});;
}

test "t31" {
    assert (parse_envs("a=b,c=d,e=f") == {"a": "b", "c": "d", "e": "f"});;
}

test "t32" {
    assert (parse_envs("a=a") == {"a": "a"});;
}

test "t33" {
    assert (
        parse_envs("a=b,c=d,e=f,g=h,i=j,k=l,m=n")
        == {"a": "b", "c": "d", "e": "f", "g": "h", "i": "j", "k": "l", "m": "n"}
    );;
}

test "t34" {
    assert (parse_envs("A=B,C=D,E=F") == {"A": "B", "C": "D", "E": "F"});;
}

test "t35" {
    assert (parse_envs("hello=world") == {"hello": "world"});;
}

test "t36" {
    assert (parse_envs("a=a,b=b") == {"a": "a", "b": "b"});;
}

test "t37" {
    assert (
        parse_envs("A=B,C=D,E=F,G=H,I=J")
        == {"A": "B", "C": "D", "E": "F", "G": "H", "I": "J"}
    );;
}

test "t38" {
    assert (parse_envs("k1=v1,k2=v2,k3=v3") == {"k1": "v1", "k2": "v2", "k3": "v3"});;
}

test "t39" {
    assert (parse_envs("k1=v1,k2=v2,k3=v3") == {"k1": "v1", "k2": "v2", "k3": "v3"});;
}

test "t40" {
    assert (parse_envs("k1=,k2=v3") == {"k1": "", "k2": "v3"});;
}

test "t41" {
    assert (parse_envs("key1=value1") == {"key1": "value1"});;
}

test "t42" {
    assert (parse_envs("a=a,b=b,c=c") == {"a": "a", "b": "b", "c": "c"});;
}

test "t43" {
    assert (
        parse_envs("key=value,key2=value2,key3=value3")
        == {"key": "value", "key2": "value2", "key3": "value3"}
    );;
}

test "t44" {
    assert (
        parse_envs("k1=v1,k2=v2,k3=v3,k4=v4")
        == {"k1": "v1", "k2": "v2", "k3": "v3", "k4": "v4"}
    );;
}

test "t45" {
    assert (parse_envs("k1=v1,k2=v2") == {"k1": "v1", "k2": "v2"});;
}

test "t46" {
    assert (parse_envs(" a b c ") == {});;
}

test "t47" {
    assert (
        parse_envs("a=b,c=d,e=f,g=h,i=j,k=l,m=n,o=p,q=r,s=t,u=v,w=x,y=z")
        == {
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
            "y": "z"
        }
    );;
}

test "t48" {
    assert (parse_envs("a=b") == {"a": "b"});;
}

test "t49" {
    assert (parse_envs("x=y") == {"x": "y"});;
}

test "t50" {
    assert (parse_envs(None) == {});;
}

test "t51" {
    assert (
        parse_envs("k1=v1,k2=v2,k3=v3,k4=v4,k5=v5")
        == {"k1": "v1", "k2": "v2", "k3": "v3", "k4": "v4", "k5": "v5"}
    );;
}

test "t52" {
    assert (
        parse_envs("a=b,c=d,e=f,g=h,i=j")
        == {"a": "b", "c": "d", "e": "f", "g": "h", "i": "j"}
    );;
}

test "t53" {
    assert (parse_envs("a=1,b=2,c=3") == {"a": "1", "b": "2", "c": "3"});;
}

test "t54" {
    assert (parse_envs("a=b,c=d") == {"a": "b", "c": "d"});;
}

test "t55" {
    assert (parse_envs("k1=,k2=") == {"k1": "", "k2": ""});;
}

test "t56" {
    assert (parse_envs("hello") == {});;
}

test "t57" {
    assert (
        parse_envs("hello=world,foo=bar,baz=qux")
        == {"hello": "world", "foo": "bar", "baz": "qux"}
    );;
}
