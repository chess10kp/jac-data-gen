def islambda(v):
    """ Checks if v is a lambda function """
    LAMBDA = lambda:0
    return isinstance(v, type(LAMBDA)) and v.__name__ == LAMBDA.__name__

assert islambda(3+4j) == False
assert islambda(lambda x:0) == True
assert islambda(lambda x, y, z, a, b, c, d: x) == True
assert islambda(lambda x, **y: x+y['y']) == True
assert islambda(lambda x, **y: 0) == True
assert islambda(lambda **kwargs: kwargs['x'] + kwargs['y']) == True
assert islambda(lambda:0**2) == True
assert islambda(lambda x=1, y=2: 0) == True
assert islambda(lambda *args: args[0] + args[1]) == True
assert islambda(lambda x,y:x+y) == True
assert islambda(lambda:0) == True
assert islambda(lambda x, y, z: 0) == True
assert islambda(lambda **kwargs: kwargs['x']) == True
assert islambda(lambda x, y:x+y+1) == True
assert islambda(lambda x, y, z:x+y+z+1) == True
assert islambda(lambda: 0) == True
assert islambda(False) == False
assert islambda("") == False
assert islambda(lambda: None) == True
assert islambda(lambda x: x + y) == True
assert islambda(lambda x=1, y=2, *z, a, b: 0) == True
assert islambda(lambda x,y,z:0) == True
assert islambda(lambda x, y: x + y) == True
assert islambda(lambda x, y, z, a, b: x) == True
assert islambda(lambda x, y, z, a: x) == True
assert islambda(lambda x, y, z: x + y + z) == True
assert islambda(lambda **x: 42) == True
assert islambda(0.0) == False
assert islambda(lambda x, y, z, a, b, c, d, e: x) == True
assert islambda(lambda:1) == True
assert islambda(lambda x, y, z=1: 0) == True
assert islambda(lambda x=1, y=2, *z, a, b=1, **c: 0) == True
assert islambda(lambda x: x+1) == True
assert islambda(lambda:0+1+2+3+4+5+6+7+8+9+10) == True
assert islambda(lambda x=2,y=2:x+y) == True
assert islambda(lambda:lambda:0) == True
assert islambda(lambda x, y, z, w:x+y+z+w) == True
assert islambda(lambda: 1) == True
assert islambda(lambda: x) == True
assert islambda(set([1])) == False
assert islambda(lambda: 42) == True
assert islambda(lambda x, y, z, a, b, c: x) == True
assert islambda(lambda x, y, z, w, *args:x+y+z+w+sum(args)+1) == True
assert islambda(lambda x,y,z=0, a=0,b=0:0) == True
assert islambda(type(1)) == False
assert islambda(lambda x, y, z:x+y+z) == True
assert islambda(lambda x, y:x+y) == True
assert islambda(lambda x, y, **z: 42) == True
assert islambda(lambda x=None: x) == True
assert islambda(lambda x:x+1) == True
assert islambda(lambda **kwargs: kwargs['x'] + 1) == True
assert islambda(lambda x=1, *y, **z: 0) == True
assert islambda([]) == False
assert islambda(int) == False
assert islambda("a") == False
assert islambda(lambda x=None, y=None: x + y) == True
assert islambda(lambda x, y, z, w, *args, q, **kwargs:x+y+z+w+sum(args)+sum(kwargs.values())+q+1) == True
assert islambda(lambda **kwargs: 0) == True
assert islambda({}) == False
assert islambda(lambda x, *y: 0) == True
assert islambda(lambda x=1, y=2, *z, **a: 0) == True
assert islambda(lambda x: x + 1) == True
assert islambda(lambda *args: 0) == True
assert islambda(lambda x,y=2:x+y) == True
assert islambda(lambda x:lambda:x) == True
assert islambda(lambda x, *y: x+y[0]) == True
assert islambda(lambda x, y, z, w, *args, **kwargs:x+y+z+w+sum(args)+sum(kwargs.values())) == True
assert islambda(set()) == False
assert islambda(lambda x,y,z=0, a=0:0) == True
assert islambda(lambda x=1, y=2, *z, a=2: 0) == True
assert islambda(lambda x, y: x+y) == True
assert islambda(0) == False
assert islambda(lambda x: 1) == True
assert islambda(lambda x,y,z=0:0) == True
assert islambda(object) == False
assert islambda(type(None)) == False
assert islambda(1.1) == False
assert islambda(True) == False
assert islambda(3.14) == False
assert islambda(lambda x,y,z=0, a=0,b=0,c=0:0) == True
assert islambda(lambda x: x) == True
assert islambda(lambda:0+1) == True
assert islambda(lambda x, y=None, z=None: x + y + z) == True
assert islambda(frozenset()) == False
assert islambda(frozenset([1])) == False
assert islambda(None) == False
assert islambda(lambda x,y=0:0) == True
assert islambda(lambda x=3:0) == True
assert islambda(lambda:0*2) == True
assert islambda(lambda x,y:0) == True
assert islambda(lambda x: 0) == True
assert islambda(lambda *args: args[0] + 1) == True
assert islambda(lambda *x:x) == True
assert islambda(lambda *x: 42) == True
assert islambda(lambda x=None, y=None, z=None: x + y + z) == True
assert islambda(lambda x, y, z: x) == True
assert islambda({'a': 1}) == False
assert islambda(lambda x:x) == True
assert islambda(lambda **x:x) == True
assert islambda(lambda x, y, z, w, *args, q, **kwargs:x+y+z+w+sum(args)+sum(kwargs.values())+q) == True
assert islambda(lambda x, y, z, a, b, c, d, e, f: x) == True
assert islambda(lambda x:x**2) == True
assert islambda(lambda:0**2+1) == True
assert islambda(lambda x=None: x + 1) == True
assert islambda(lambda x, y, z, w, *args:x+y+z+w+sum(args)) == True
assert islambda(lambda x, y=2, *z, **a: 0) == True
assert islambda(lambda *args: args[0]) == True
assert islambda(1) == False
assert islambda(lambda x:x*2) == True
assert islambda(object()) == False
assert islambda(lambda x=None: x + y) == True
assert islambda(lambda x, y=None: x + y) == True
assert islambda(lambda x, *y, **z: x+y[0]+z['z']) == True
assert islambda(1.0) == False
assert islambda([1]) == False
assert islambda(lambda x=1, y=2, *z, a, b=1: 0) == True
assert islambda(lambda x, y, z, w, *args, **kwargs:x+y+z+w+sum(args)+sum(kwargs.values())+1) == True
assert islambda(lambda x, y, z, w:x+y+z+w+1) == True
assert islambda(lambda x:x**2+x) == True
