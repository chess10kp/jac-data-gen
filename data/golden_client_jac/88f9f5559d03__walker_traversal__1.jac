"""Hand-authored idiomatic Jac conversion examples (scale the idiomatic core).

The quality tier the volume transpile cannot provide: graph-spatial walkers,
archetypes, and clean typed Jac. Appends to 01-sft-dpo/dataset/conversion/sft.jsonl and
re-validates every line through `jac run`. Run AFTER seed_conversion.jac:
    jac run srccurrent/jacgen/seed_conversion.jac   # writes the base 32
    jac run srccurrent/jacgen/idiomatic_batch.jac   # appends this batch
"""

import from writer { make_sft_example, append_jsonl, revalidate_example }
import from typing { Any }

glob SFT_PATH: str = "01-sft-dpo/dataset/conversion/sft.jsonl";

glob SEEDS: list[dict] = [
    # ================= graph-spatial (walker / node / edge) =================
    {
        "difficulty": "composed", "expected": "24",
        "py": '''
def product_of_tree(tree: dict, start: str, vals: dict) -> int:
    """Multiply the values of all nodes reachable from start."""
    result = 1
    stack = [start]
    while stack:
        node = stack.pop()
        result *= vals[node]
        stack.extend(tree.get(node, []))
    return result
''',
        "jac": '''
node TNode {
    has val: int;
}

walker Product {
    has result: int = 1;

    can mul with TNode entry {
        self.result *= here.val;
        visit [-->];
    }
}

with entry {
    a = TNode(val=2);
    b = TNode(val=3);
    c = TNode(val=4);
    root ++> a;
    a ++> b;
    a ++> c;
    w = a spawn Product();
    print(w.result);
}
'''
    },
    {
        "difficulty": "composed", "expected": "9",
        "py": '''
def max_in_chain(chain: list) -> int:
    """Return the maximum value in a linked chain of numbers."""
    best = chain[0]
    for v in chain:
        if v > best:
            best = v
    return best
''',
        "jac": '''
node NNode {
    has val: int;
}

walker MaxVal {
    has best: int = -2147483648;

    can chk with NNode entry {
        if here.val > self.best { self.best = here.val; }
        visit [-->];
    }
}

with entry {
    a = NNode(val=3);
    b = NNode(val=9);
    c = NNode(val=5);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn MaxVal();
    print(w.best);
}
'''
    },
    {
        "difficulty": "composed", "expected": "2",
        "py": '''
def count_above(tree: dict, start: str, vals: dict, threshold: int) -> int:
    """Count nodes whose value exceeds threshold."""
    count = 0
    stack = [start]
    while stack:
        node = stack.pop()
        if vals[node] > threshold:
            count += 1
        stack.extend(tree.get(node, []))
    return count
''',
        "jac": '''
node VNode {
    has val: int;
}

walker CountAbove {
    has threshold: int;
    has count: int = 0;

    can chk with VNode entry {
        if here.val > self.threshold { self.count += 1; }
        visit [-->];
    }
}

with entry {
    a = VNode(val=3);
    b = VNode(val=7);
    c = VNode(val=9);
    d = VNode(val=2);
    root ++> a;
    a ++> b;
    b ++> c;
    c ++> d;
    w = a spawn CountAbove(threshold=5);
    print(w.count);
}
'''
    },
    {
        "difficulty": "composed", "expected": "abc",
        "py": '''
def concat_labels(tree: dict, start: str, labels: dict) -> str:
    """Concatenate node labels along a chain."""
    result = ""
    node = start
    while node is not None:
        result += labels[node]
        children = tree.get(node, [])
        node = children[0] if children else None
    return result
''',
        "jac": '''
node LabelNode {
    has label: str;
}

walker Concat {
    has out: str = "";

    can grab with LabelNode entry {
        self.out += here.label;
        visit [-->];
    }
}

with entry {
    a = LabelNode(label="a");
    b = LabelNode(label="b");
    c = LabelNode(label="c");
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn Concat();
    print(w.out);
}
'''
    },
    {
        "difficulty": "composed", "expected": "7",
        "py": '''
def sum_leaves(tree: dict, start: str, vals: dict) -> int:
    """Sum the values of leaf nodes (nodes with no children)."""
    total = 0
    stack = [start]
    while stack:
        node = stack.pop()
        children = tree.get(node, [])
        if not children:
            total += vals[node]
        stack.extend(children)
    return total
''',
        "jac": '''
node Leaf {
    has val: int;
}

walker SumLeaves {
    has total: int = 0;

    can chk with Leaf entry {
        if not [-->] { self.total += here.val; }
        visit [-->];
    }
}

with entry {
    r1 = Leaf(val=1);
    r2 = Leaf(val=2);
    r3 = Leaf(val=3);
    r4 = Leaf(val=4);
    root ++> r1;
    r1 ++> r2;
    r1 ++> r3;
    r2 ++> r4;
    w = r1 spawn SumLeaves();
    print(w.total);
}
'''
    },
    {
        "difficulty": "composed", "expected": "True",
        "py": '''
def all_positive(tree: dict, start: str, vals: dict) -> bool:
    """Return True if every reachable node has a positive value."""
    stack = [start]
    while stack:
        node = stack.pop()
        if vals[node] <= 0:
            return False
        stack.extend(tree.get(node, []))
    return True
''',
        "jac": '''
node PNode {
    has val: int;
}

walker AllPositive {
    has ok: bool = True;

    can chk with PNode entry {
        if here.val <= 0 {
            self.ok = False;
            disengage;
        }
        visit [-->];
    }
}

with entry {
    a = PNode(val=1);
    b = PNode(val=2);
    c = PNode(val=3);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn AllPositive();
    print(w.ok);
}
'''
    },
    {
        "difficulty": "composed", "expected": "2",
        "py": '''
def count_even(tree: dict, start: str, vals: dict) -> int:
    """Count reachable nodes with an even value."""
    count = 0
    stack = [start]
    while stack:
        node = stack.pop()
        if vals[node] % 2 == 0:
            count += 1
        stack.extend(tree.get(node, []))
    return count
''',
        "jac": '''
node ENode {
    has val: int;
}

walker CountEven {
    has count: int = 0;

    can chk with ENode entry {
        if here.val % 2 == 0 { self.count += 1; }
        visit [-->];
    }
}

with entry {
    a = ENode(val=1);
    b = ENode(val=2);
    c = ENode(val=4);
    d = ENode(val=3);
    root ++> a;
    a ++> b;
    b ++> c;
    c ++> d;
    w = a spawn CountEven();
    print(w.count);
}
'''
    },
    {
        "difficulty": "composed", "expected": "20",
        "py": '''
def average_value(tree: dict, start: str, vals: dict) -> int:
    """Return the rounded average of all reachable node values."""
    total = 0
    count = 0
    stack = [start]
    while stack:
        node = stack.pop()
        total += vals[node]
        count += 1
        stack.extend(tree.get(node, []))
    return round(total / count)
''',
        "jac": '''
node ANode {
    has val: int;
}

walker Average {
    has total: int = 0;
    has count: int = 0;

    can chk with ANode entry {
        self.total += here.val;
        self.count += 1;
        visit [-->];
    }
}

with entry {
    a = ANode(val=10);
    b = ANode(val=20);
    c = ANode(val=30);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn Average();
    print(round(w.total / w.count));
}
'''
    },
    {
        "difficulty": "composed", "expected": "True",
        "py": '''
def contains_value(tree: dict, start: str, vals: dict, target: int) -> bool:
    """Return True if any reachable node holds target."""
    stack = [start]
    while stack:
        node = stack.pop()
        if vals[node] == target:
            return True
        stack.extend(tree.get(node, []))
    return False
''',
        "jac": '''
node SNode {
    has val: int;
}

walker Contains {
    has target: int;
    has found: bool = False;

    can chk with SNode entry {
        if here.val == self.target {
            self.found = True;
            disengage;
        }
        visit [-->];
    }
}

with entry {
    a = SNode(val=5);
    b = SNode(val=8);
    c = SNode(val=13);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn Contains(target=13);
    print(w.found);
}
'''
    },
    {
        "difficulty": "composed", "expected": "6.0",
        "py": '''
def sum_edge_weights(edges: list) -> float:
    """Sum the weights along a path of edges."""
    total = 0.0
    for w in edges:
        total += w
    return total
''',
        "jac": '''
node Stop {
    has name: str;
}

edge Road {
    has weight: float = 0.0;
}

walker SumWeights {
    has total: float = 0.0;

    can step with Stop entry {
        for e in [edge -->] {
            self.total += e.weight;
        }
        visit [-->];
    }
}

with entry {
    a = Stop(name="a");
    b = Stop(name="b");
    c = Stop(name="c");
    root ++> a;
    a +>:Road(weight=2.0):+> b;
    b +>:Road(weight=4.0):+> c;
    w = a spawn SumWeights();
    print(w.total);
}
'''
    },
    # ================= archetype (obj / enum) =================
    {
        "difficulty": "idiomatic", "expected": "1",
        "py": '''
class Counter:
    """A bidirectional counter."""
    def __init__(self):
        self.value = 0

    def inc(self) -> None:
        self.value += 1

    def dec(self) -> None:
        self.value -= 1

    def get(self) -> int:
        return self.value
''',
        "jac": '''
obj Counter {
    has value: int = 0;

    def inc() -> None { self.value += 1; }

    def dec() -> None { self.value -= 1; }

    def get() -> int { return self.value; }
}

with entry {
    c = Counter();
    c.inc();
    c.inc();
    c.dec();
    print(c.get());
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "212.0",
        "py": '''
class Temperature:
    """A temperature in Celsius."""
    def __init__(self, celsius: float):
        self.celsius = celsius

    def to_fahrenheit(self) -> float:
        return self.celsius * 9 / 5 + 32
''',
        "jac": '''
obj Temperature {
    has celsius: float;

    def to_fahrenheit() -> float {
        return self.celsius * 9 / 5 + 32;
    }
}

with entry {
    t = Temperature(celsius=100.0);
    print(t.to_fahrenheit());
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "7.21",
        "py": '''
import math


class Vector2D:
    """A 2D vector."""
    def __init__(self, x: float, y: float):
        self.x = x
        self.y = y

    def add(self, other: "Vector2D") -> "Vector2D":
        return Vector2D(self.x + other.x, self.y + other.y)

    def magnitude(self) -> float:
        return math.sqrt(self.x ** 2 + self.y ** 2)
''',
        "jac": '''
import math;

obj Vector2D {
    has x: float;
    has y: float;

    def add(other: Vector2D) -> Vector2D {
        return Vector2D(x=self.x + other.x, y=self.y + other.y);
    }

    def magnitude() -> float {
        return math.sqrt(self.x ** 2 + self.y ** 2);
    }
}

with entry {
    v = Vector2D(x=1.0, y=2.0).add(Vector2D(x=3.0, y=4.0));
    print(round(v.magnitude(), 2));
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "SOUTH",
        "py": '''
from enum import Enum


class Direction(Enum):
    NORTH = "NORTH"
    SOUTH = "SOUTH"
    EAST = "EAST"
    WEST = "WEST"


def opposite(d: Direction) -> Direction:
    """Return the opposite direction."""
    pairs = {Direction.NORTH: Direction.SOUTH, Direction.SOUTH: Direction.NORTH,
             Direction.EAST: Direction.WEST, Direction.WEST: Direction.EAST}
    return pairs[d]
''',
        "jac": '''
enum Direction {
    NORTH = "NORTH",
    SOUTH = "SOUTH",
    EAST = "EAST",
    WEST = "WEST"
}

def opposite(d: Direction) -> Direction {
    pairs: dict = {
        Direction.NORTH: Direction.SOUTH,
        Direction.SOUTH: Direction.NORTH,
        Direction.EAST: Direction.WEST,
        Direction.WEST: Direction.EAST
    };
    return pairs[d];
}

with entry {
    print(opposite(Direction.NORTH).value);
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "20.0",
        "py": '''
class Accumulator:
    """Collects numbers and reports their mean."""
    def __init__(self):
        self.items = []

    def add(self, x: float) -> None:
        self.items.append(x)

    def mean(self) -> float:
        return sum(self.items) / len(self.items)
''',
        "jac": '''
obj Accumulator {
    has items: list[float] = [];

    def add(x: float) -> None { self.items.append(x); }

    def mean() -> float { return sum(self.items) / len(self.items); }
}

with entry {
    acc = Accumulator();
    acc.add(10.0);
    acc.add(20.0);
    acc.add(30.0);
    print(acc.mean());
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "True\nFalse",
        "py": '''
class Interval:
    """A closed numeric interval."""
    def __init__(self, low: int, high: int):
        self.low = low
        self.high = high

    def contains(self, x: int) -> bool:
        return self.low <= x <= self.high
''',
        "jac": '''
obj Interval {
    has low: int;
    has high: int;

    def contains(x: int) -> bool {
        return self.low <= x and x <= self.high;
    }
}

with entry {
    iv = Interval(low=1, high=10);
    print(iv.contains(5));
    print(iv.contains(15));
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "5",
        "py": '''
class Inventory:
    """Tracks item quantities."""
    def __init__(self):
        self.stock = {}

    def add(self, item: str, qty: int) -> None:
        self.stock[item] = self.stock.get(item, 0) + qty

    def total(self) -> int:
        return sum(self.stock.values())
''',
        "jac": '''
obj Inventory {
    has stock: dict[str, int] = {};

    def add(item: str, qty: int) -> None {
        self.stock[item] = self.stock.get(item, 0) + qty;
    }

    def total() -> int { return sum(self.stock.values()); }
}

with entry {
    inv = Inventory();
    inv.add("apple", 3);
    inv.add("apple", 2);
    print(inv.total());
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "90.0",
        "py": '''
class Gradebook:
    """Stores grades and computes the average."""
    def __init__(self):
        self.grades = []

    def add(self, g: float) -> None:
        self.grades.append(g)

    def average(self) -> float:
        return sum(self.grades) / len(self.grades)
''',
        "jac": '''
obj Gradebook {
    has grades: list[float] = [];

    def add(g: float) -> None { self.grades.append(g); }

    def average() -> float { return sum(self.grades) / len(self.grades); }
}

with entry {
    gb = Gradebook();
    gb.add(80.0);
    gb.add(90.0);
    gb.add(100.0);
    print(gb.average());
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "3.0",
        "py": '''
import math


class Point3D:
    """A point in 3D space."""
    def __init__(self, x: float, y: float, z: float):
        self.x = x
        self.y = y
        self.z = z

    def distance(self, other: "Point3D") -> float:
        return math.sqrt((self.x - other.x) ** 2 + (self.y - other.y) ** 2 + (self.z - other.z) ** 2)
''',
        "jac": '''
import math;

obj Point3D {
    has x: float;
    has y: float;
    has z: float;

    def distance(other: Point3D) -> float {
        return math.sqrt(
            (self.x - other.x) ** 2 + (self.y - other.y) ** 2 + (self.z - other.z) ** 2
        );
    }
}

with entry {
    p = Point3D(x=0.0, y=0.0, z=0.0);
    q = Point3D(x=1.0, y=2.0, z=2.0);
    print(p.distance(q));
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "2\n8",
        "py": '''
class RunningStats:
    """Tracks the min and max of a stream of integers."""
    def __init__(self):
        self.lo = None
        self.hi = None

    def add(self, x: int) -> None:
        if self.lo is None or x < self.lo:
            self.lo = x
        if self.hi is None or x > self.hi:
            self.hi = x
''',
        "jac": '''
obj RunningStats {
    has lo: int = 2147483647;
    has hi: int = -2147483648;

    def add(x: int) -> None {
        if x < self.lo { self.lo = x; }
        if x > self.hi { self.hi = x; }
    }
}

with entry {
    rs = RunningStats();
    rs.add(5);
    rs.add(2);
    rs.add(8);
    print(rs.lo);
    print(rs.hi);
}
'''
    },
    # ================= atomic-clean (idiomatic typed def) =================
    {
        "difficulty": "atomic", "expected": "10.0",
        "py": '''
def clamp(value: float, low: float, high: float) -> float:
    """Clamp value into the inclusive range [low, high]."""
    if value < low:
        return low
    if value > high:
        return high
    return value
''',
        "jac": '''
def clamp(value: float, low: float, high: float) -> float {
    if value < low { return low; }
    if value > high { return high; }
    return value;
}

with entry {
    print(clamp(15.0, 0.0, 10.0));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "True\nFalse",
        "py": '''
def is_anagram(a: str, b: str) -> bool:
    """Return True if a and b are anagrams."""
    return sorted(a) == sorted(b)
''',
        "jac": '''
def is_anagram(a: str, b: str) -> bool {
    return sorted(a) == sorted(b);
}

with entry {
    print(is_anagram("listen", "silent"));
    print(is_anagram("hello", "world"));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "15",
        "py": '''
def digit_sum(n: int) -> int:
    """Return the sum of the decimal digits of n."""
    total = 0
    for ch in str(n):
        total += int(ch)
    return total
''',
        "jac": '''
def digit_sum(n: int) -> int {
    total = 0;
    for ch in str(n) { total += int(ch); }
    return total;
}

with entry {
    print(digit_sum(12345));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "Hello World",
        "py": '''
def title_case(s: str) -> str:
    """Capitalize the first letter of each word."""
    return " ".join(word.capitalize() for word in s.split())
''',
        "jac": '''
def title_case(s: str) -> str {
    return " ".join([word.capitalize() for word in s.split()]);
}

with entry {
    print(title_case("hello world"));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "4",
        "py": '''
def second_largest(nums: list) -> int:
    """Return the second largest distinct value."""
    distinct = sorted(set(nums))
    return distinct[-2]
''',
        "jac": '''
def second_largest(nums: list[int]) -> int {
    distinct = sorted(set(nums));
    return distinct[-2];
}

with entry {
    print(second_largest([3, 1, 4, 1, 5]));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "[1, 2, 3]",
        "py": '''
def dedupe(nums: list) -> list:
    """Remove duplicates while preserving order."""
    seen = set()
    out = []
    for n in nums:
        if n not in seen:
            seen.add(n)
            out.append(n)
    return out
''',
        "jac": '''
def dedupe(nums: list[int]) -> list[int] {
    seen: set = set();
    out: list[int] = [];
    for n in nums {
        if n not in seen {
            seen.add(n);
            out.append(n);
        }
    }
    return out;
}

with entry {
    print(dedupe([1, 2, 2, 3, 1]));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "{'a': 2, 'b': 1}",
        "py": '''
def char_frequency(s: str) -> dict:
    """Return a mapping of character to count."""
    freq = {}
    for ch in s:
        freq[ch] = freq.get(ch, 0) + 1
    return freq
''',
        "jac": '''
def char_frequency(s: str) -> dict[str, int] {
    freq: dict[str, int] = {};
    for ch in s {
        freq[ch] = freq.get(ch, 0) + 1;
    }
    return freq;
}

with entry {
    print(char_frequency("aab"));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "12",
        "py": '''
def lcm(a: int, b: int) -> int:
    """Return the least common multiple of a and b."""
    def gcd(x, y):
        while y:
            x, y = y, x % y
        return x
    return a * b // gcd(a, b)
''',
        "jac": '''
def gcd(a: int, b: int) -> int {
    while b != 0 { (a, b) = (b, a % b); }
    return a;
}

def lcm(a: int, b: int) -> int {
    return a * b // gcd(a, b);
}

with entry {
    print(lcm(4, 6));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "True",
        "py": '''
def is_armstrong(n: int) -> bool:
    """Return True if n equals the sum of its digits raised to the digit count."""
    digits = str(n)
    power = len(digits)
    return n == sum(int(d) ** power for d in digits)
''',
        "jac": '''
def is_armstrong(n: int) -> bool {
    digits = str(n);
    power = len(digits);
    return n == sum([int(d) ** power for d in digits]);
}

with entry {
    print(is_armstrong(153));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "3",
        "py": '''
def count_words(s: str) -> int:
    """Return the number of whitespace-separated words."""
    return len(s.split())
''',
        "jac": '''
def count_words(s: str) -> int {
    return len(s.split());
}

with entry {
    print(count_words("one two three"));
}
'''
    }
];


def build() {
    examples: list[dict] = [];
    for s in SEEDS {
        py: str = str(s["py"]);
        jaccode: str = str(s["jac"]);
        difficulty: str = str(s["difficulty"]);
        expected: str = str(s["expected"]);
        ex: dict = make_sft_example(py, jaccode, difficulty, expected, "generated_idiomatic");
        append_jsonl(SFT_PATH, ex);
        examples.append(ex);
    }
    print("appended " + str(len(examples)) + " idiomatic examples -> " + SFT_PATH);
    print("re-validating through `jac run`...");
    failures: int = 0;
    for (i, ex) in enumerate(examples) {
        (ok, detail) = revalidate_example(ex);
        if not ok { failures += 1; print("  FAIL #" + str(i) + ": " + detail); }
    }
    print(str(len(examples) - failures) + "/" + str(len(examples)) + " re-validated, " + str(failures) + " failed");
}


with entry {
    build();
}
