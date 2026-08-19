"""Second hand-authored idiomatic batch (scale the idiomatic core further).

Appends to 01-sft-dpo/dataset/conversion/sft.jsonl and re-validates. Run AFTER
seed_conversion.jac and idiomatic_batch.jac.
"""

import from writer { make_sft_example, append_jsonl, revalidate_example }
import from typing { Any }

glob SFT_PATH: str = "01-sft-dpo/dataset/conversion/sft.jsonl";

glob SEEDS: list[dict] = [
    # ================= graph-spatial =================
    {
        "difficulty": "composed", "expected": "14",
        "py": '''
def sum_squares(tree: dict, start: str, vals: dict) -> int:
    """Sum the squares of all reachable node values."""
    total = 0
    stack = [start]
    while stack:
        node = stack.pop()
        total += vals[node] ** 2
        stack.extend(tree.get(node, []))
    return total
''',
        "jac": '''
node QNode {
    has val: int;
}

walker SumSquares {
    has total: int = 0;

    can chk with QNode entry {
        self.total += here.val ** 2;
        visit [-->];
    }
}

with entry {
    a = QNode(val=1);
    b = QNode(val=2);
    c = QNode(val=3);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn SumSquares();
    print(w.total);
}
'''
    },
    {
        "difficulty": "composed", "expected": "[2, 4]",
        "py": '''
def collect_even(tree: dict, start: str, vals: dict) -> list:
    """Collect reachable even values, sorted."""
    out = []
    stack = [start]
    while stack:
        node = stack.pop()
        if vals[node] % 2 == 0:
            out.append(vals[node])
        stack.extend(tree.get(node, []))
    return sorted(out)
''',
        "jac": '''
node CNode {
    has val: int;
}

walker CollectEven {
    has out: list[int] = [];

    can chk with CNode entry {
        if here.val % 2 == 0 { self.out.append(here.val); }
        visit [-->];
    }
}

with entry {
    a = CNode(val=1);
    b = CNode(val=2);
    c = CNode(val=3);
    d = CNode(val=4);
    root ++> a;
    a ++> b;
    b ++> c;
    c ++> d;
    w = a spawn CollectEven();
    print(sorted(w.out));
}
'''
    },
    {
        "difficulty": "composed", "expected": "2",
        "py": '''
def count_starting_with(tree: dict, start: str, names: dict, prefix: str) -> int:
    """Count reachable nodes whose name starts with prefix."""
    count = 0
    stack = [start]
    while stack:
        node = stack.pop()
        if names[node].startswith(prefix):
            count += 1
        stack.extend(tree.get(node, []))
    return count
''',
        "jac": '''
node Named {
    has name: str;
}

walker CountPrefix {
    has prefix: str;
    has count: int = 0;

    can chk with Named entry {
        if here.name.startswith(self.prefix) { self.count += 1; }
        visit [-->];
    }
}

with entry {
    a = Named(name="alice");
    b = Named(name="bob");
    c = Named(name="amy");
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn CountPrefix(prefix="a");
    print(w.count);
}
'''
    },
    {
        "difficulty": "composed", "expected": "True",
        "py": '''
def any_negative(tree: dict, start: str, vals: dict) -> bool:
    """Return True if any reachable node has a negative value."""
    stack = [start]
    while stack:
        node = stack.pop()
        if vals[node] < 0:
            return True
        stack.extend(tree.get(node, []))
    return False
''',
        "jac": '''
node DNode {
    has val: int;
}

walker AnyNegative {
    has found: bool = False;

    can chk with DNode entry {
        if here.val < 0 {
            self.found = True;
            disengage;
        }
        visit [-->];
    }
}

with entry {
    a = DNode(val=1);
    b = DNode(val=-2);
    c = DNode(val=3);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn AnyNegative();
    print(w.found);
}
'''
    },
    {
        "difficulty": "composed", "expected": "3",
        "py": '''
def max_label_length(tree: dict, start: str, labels: dict) -> int:
    """Return the length of the longest reachable label."""
    best = 0
    stack = [start]
    while stack:
        node = stack.pop()
        if len(labels[node]) > best:
            best = len(labels[node])
        stack.extend(tree.get(node, []))
    return best
''',
        "jac": '''
node LNode {
    has label: str;
}

walker MaxLen {
    has best: int = 0;

    can chk with LNode entry {
        if len(here.label) > self.best { self.best = len(here.label); }
        visit [-->];
    }
}

with entry {
    a = LNode(label="a");
    b = LNode(label="bbb");
    c = LNode(label="cc");
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn MaxLen();
    print(w.best);
}
'''
    },
    {
        "difficulty": "composed", "expected": "6",
        "py": '''
def product_positive(tree: dict, start: str, vals: dict) -> int:
    """Multiply only the positive reachable values."""
    result = 1
    stack = [start]
    while stack:
        node = stack.pop()
        if vals[node] > 0:
            result *= vals[node]
        stack.extend(tree.get(node, []))
    return result
''',
        "jac": '''
node MNode {
    has val: int;
}

walker ProductPositive {
    has result: int = 1;

    can chk with MNode entry {
        if here.val > 0 { self.result *= here.val; }
        visit [-->];
    }
}

with entry {
    a = MNode(val=2);
    b = MNode(val=-1);
    c = MNode(val=3);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn ProductPositive();
    print(w.result);
}
'''
    },
    {
        "difficulty": "composed", "expected": "6",
        "py": '''
def value_span(tree: dict, start: str, vals: dict) -> int:
    """Return max minus min over reachable values."""
    lo = None
    hi = None
    stack = [start]
    while stack:
        node = stack.pop()
        v = vals[node]
        if lo is None or v < lo:
            lo = v
        if hi is None or v > hi:
            hi = v
        stack.extend(tree.get(node, []))
    return hi - lo
''',
        "jac": '''
node RNode {
    has val: int;
}

walker Span {
    has lo: int = 2147483647;
    has hi: int = -2147483648;

    can chk with RNode entry {
        if here.val < self.lo { self.lo = here.val; }
        if here.val > self.hi { self.hi = here.val; }
        visit [-->];
    }
}

with entry {
    a = RNode(val=5);
    b = RNode(val=2);
    c = RNode(val=8);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn Span();
    print(w.hi - w.lo);
}
'''
    },
    {
        "difficulty": "composed", "expected": "2",
        "py": '''
def count_leaves(tree: dict, start: str) -> int:
    """Count leaf nodes (no children) reachable from start."""
    count = 0
    stack = [start]
    while stack:
        node = stack.pop()
        children = tree.get(node, [])
        if not children:
            count += 1
        stack.extend(children)
    return count
''',
        "jac": '''
node BNode {
    has name: str;
}

walker CountLeaves {
    has count: int = 0;

    can chk with BNode entry {
        if not [-->] { self.count += 1; }
        visit [-->];
    }
}

with entry {
    r1 = BNode(name="r1");
    r2 = BNode(name="r2");
    r3 = BNode(name="r3");
    r4 = BNode(name="r4");
    root ++> r1;
    r1 ++> r2;
    r1 ++> r3;
    r2 ++> r4;
    w = r1 spawn CountLeaves();
    print(w.count);
}
'''
    },
    # ================= archetype =================
    {
        "difficulty": "idiomatic", "expected": "70",
        "py": '''
class Wallet:
    """A simple wallet."""
    def __init__(self, balance: int = 0):
        self.balance = balance

    def add(self, amount: int) -> None:
        self.balance += amount

    def spend(self, amount: int) -> None:
        self.balance -= amount
''',
        "jac": '''
obj Wallet {
    has balance: int = 0;

    def add(amount: int) -> None { self.balance += amount; }

    def spend(amount: int) -> None { self.balance -= amount; }
}

with entry {
    w = Wallet(balance=100);
    w.spend(30);
    print(w.balance);
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "red",
        "py": '''
from enum import Enum


class Suit(Enum):
    HEARTS = "HEARTS"
    DIAMONDS = "DIAMONDS"
    CLUBS = "CLUBS"
    SPADES = "SPADES"


def color(s: Suit) -> str:
    """Return the color of a suit."""
    if s in (Suit.HEARTS, Suit.DIAMONDS):
        return "red"
    return "black"
''',
        "jac": '''
enum Suit {
    HEARTS = "HEARTS",
    DIAMONDS = "DIAMONDS",
    CLUBS = "CLUBS",
    SPADES = "SPADES"
}

def color(s: Suit) -> str {
    if s == Suit.HEARTS or s == Suit.DIAMONDS { return "red"; }
    return "black";
}

with entry {
    print(color(Suit.HEARTS));
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "False",
        "py": '''
class ToggleSwitch:
    """A boolean switch."""
    def __init__(self):
        self.on = False

    def toggle(self) -> None:
        self.on = not self.on
''',
        "jac": '''
obj ToggleSwitch {
    has on: bool = False;

    def toggle() -> None { self.on = not self.on; }
}

with entry {
    s = ToggleSwitch();
    s.toggle();
    s.toggle();
    print(s.on);
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "2",
        "py": '''
class Histogram:
    """Counts occurrences of labels."""
    def __init__(self):
        self.bins = {}

    def add(self, label: str) -> None:
        self.bins[label] = self.bins.get(label, 0) + 1

    def count(self, label: str) -> int:
        return self.bins.get(label, 0)
''',
        "jac": '''
obj Histogram {
    has bins: dict[str, int] = {};

    def add(label: str) -> None {
        self.bins[label] = self.bins.get(label, 0) + 1;
    }

    def count(label: str) -> int { return self.bins.get(label, 0); }
}

with entry {
    h = Histogram();
    h.add("a");
    h.add("b");
    h.add("a");
    print(h.count("a"));
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "2",
        "py": '''
class Playlist:
    """An ordered list of tracks."""
    def __init__(self):
        self.tracks = []

    def add(self, track: str) -> None:
        self.tracks.append(track)

    def length(self) -> int:
        return len(self.tracks)
''',
        "jac": '''
obj Playlist {
    has tracks: list[str] = [];

    def add(track: str) -> None { self.tracks.append(track); }

    def length() -> int { return len(self.tracks); }
}

with entry {
    p = Playlist();
    p.add("x");
    p.add("y");
    print(p.length());
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "273.15",
        "py": '''
class Temperature:
    """A temperature in Celsius."""
    def __init__(self, celsius: float):
        self.celsius = celsius

    def to_kelvin(self) -> float:
        return self.celsius + 273.15
''',
        "jac": '''
obj Temperature {
    has celsius: float;

    def to_kelvin() -> float { return self.celsius + 273.15; }
}

with entry {
    t = Temperature(celsius=0.0);
    print(t.to_kelvin());
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "6.28",
        "py": '''
class Circle:
    """A circle."""
    def __init__(self, radius: float):
        self.radius = radius

    def circumference(self) -> float:
        return 2 * 3.14159 * self.radius
''',
        "jac": '''
obj Circle {
    has radius: float;

    def circumference() -> float { return 2 * 3.14159 * self.radius; }
}

with entry {
    c = Circle(radius=1.0);
    print(round(c.circumference(), 2));
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "Hi, Bob",
        "py": '''
class NameTag:
    """A name tag that can greet."""
    def __init__(self, name: str):
        self.name = name

    def greet(self) -> str:
        return "Hi, " + self.name
''',
        "jac": '''
obj NameTag {
    has name: str;

    def greet() -> str { return "Hi, " + self.name; }
}

with entry {
    tag = NameTag(name="Bob");
    print(tag.greet());
}
'''
    },
    # ================= atomic-clean =================
    {
        "difficulty": "atomic", "expected": "12",
        "py": '''
def sum_even(nums: list) -> int:
    """Sum the even numbers in nums."""
    return sum(n for n in nums if n % 2 == 0)
''',
        "jac": '''
def sum_even(nums: list[int]) -> int {
    return sum([n for n in nums if n % 2 == 0]);
}

with entry {
    print(sum_even([1, 2, 3, 4, 5, 6]));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "three two one",
        "py": '''
def reverse_words(s: str) -> str:
    """Reverse the order of words."""
    return " ".join(reversed(s.split()))
''',
        "jac": '''
def reverse_words(s: str) -> str {
    return " ".join(list(reversed(s.split())));
}

with entry {
    print(reverse_words("one two three"));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "True",
        "py": '''
def is_pangram(s: str) -> bool:
    """Return True if s uses every letter of the alphabet."""
    letters = set(c for c in s.lower() if c.isalpha())
    return len(letters) == 26
''',
        "jac": '''
def is_pangram(s: str) -> bool {
    letters: set = set([c for c in s.lower() if c.isalpha()]);
    return len(letters) == 26;
}

with entry {
    print(is_pangram("the quick brown fox jumps over the lazy dog"));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "3",
        "py": '''
def hamming_distance(a: str, b: str) -> int:
    """Count positions where a and b differ."""
    return sum(1 for x, y in zip(a, b) if x != y)
''',
        "jac": '''
def hamming_distance(a: str, b: str) -> int {
    count = 0;
    for (x, y) in zip(a, b) {
        if x != y { count += 1; }
    }
    return count;
}

with entry {
    print(hamming_distance("karolin", "kathrin"));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "True\nFalse",
        "py": '''
def is_sorted(nums: list) -> bool:
    """Return True if nums is in non-decreasing order."""
    return all(nums[i] <= nums[i + 1] for i in range(len(nums) - 1))
''',
        "jac": '''
def is_sorted(nums: list[int]) -> bool {
    for i in range(len(nums) - 1) {
        if nums[i] > nums[i + 1] { return False; }
    }
    return True;
}

with entry {
    print(is_sorted([1, 2, 3]));
    print(is_sorted([3, 1, 2]));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "1010",
        "py": '''
def to_binary(n: int) -> str:
    """Return the binary representation of n (without prefix)."""
    if n == 0:
        return "0"
    bits = ""
    while n > 0:
        bits = str(n % 2) + bits
        n //= 2
    return bits
''',
        "jac": '''
def to_binary(n: int) -> str {
    if n == 0 { return "0"; }
    bits = "";
    while n > 0 {
        bits = str(n % 2) + bits;
        n //= 2;
    }
    return bits;
}

with entry {
    print(to_binary(10));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "3",
        "py": '''
def count_uppercase(s: str) -> int:
    """Count the uppercase letters in s."""
    return sum(1 for c in s if c.isupper())
''',
        "jac": '''
def count_uppercase(s: str) -> int {
    count = 0;
    for c in s {
        if c.isupper() { count += 1; }
    }
    return count;
}

with entry {
    print(count_uppercase("HeLLo"));
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
