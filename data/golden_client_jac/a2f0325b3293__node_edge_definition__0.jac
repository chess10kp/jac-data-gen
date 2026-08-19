"""Third hand-authored idiomatic batch (reach the idiomatic-core target).

Adds typed-edge filters, multi-node-type traversal, enums/state-machines, and
static methods. Appends to 01-sft-dpo/dataset/conversion/sft.jsonl and re-validates. Run
AFTER seed_conversion.jac, idiomatic_batch.jac, idiomatic_batch2.jac.
"""

import from writer { make_sft_example, append_jsonl, revalidate_example }
import from typing { Any }

glob SFT_PATH: str = "01-sft-dpo/dataset/conversion/sft.jsonl";

glob SEEDS: list[dict] = [
    # ================= graph-spatial =================
    {
        "difficulty": "composed", "expected": "2",
        "py": '''
def min_value(chain: list) -> int:
    """Return the minimum value along a chain."""
    best = chain[0]
    for v in chain:
        if v < best:
            best = v
    return best
''',
        "jac": '''
node MNode {
    has val: int;
}

walker MinVal {
    has best: int = 2147483647;

    can chk with MNode entry {
        if here.val < self.best { self.best = here.val; }
        visit [-->];
    }
}

with entry {
    a = MNode(val=5);
    b = MNode(val=2);
    c = MNode(val=8);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn MinVal();
    print(w.best);
}
'''
    },
    {
        "difficulty": "composed", "expected": "[1, 2, 3]",
        "py": '''
def collect_all(tree: dict, start: str, vals: dict) -> list:
    """Collect all reachable values, sorted."""
    out = []
    stack = [start]
    while stack:
        node = stack.pop()
        out.append(vals[node])
        stack.extend(tree.get(node, []))
    return sorted(out)
''',
        "jac": '''
node CNode {
    has val: int;
}

walker CollectAll {
    has out: list[int] = [];

    can grab with CNode entry {
        self.out.append(here.val);
        visit [-->];
    }
}

with entry {
    a = CNode(val=3);
    b = CNode(val=1);
    c = CNode(val=2);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn CollectAll();
    print(sorted(w.out));
}
'''
    },
    {
        "difficulty": "composed", "expected": "2",
        "py": '''
def count_friend_edges(graph: dict, person: str) -> int:
    """Count the friendship edges leaving person."""
    return len(graph.get(person, []))
''',
        "jac": '''
node Person3 {
    has name: str;
}

edge Friend3 {}

edge Block3 {}

walker CountFriends {
    has count: int = 0;

    can chk with Person3 entry {
        self.count += len([->:Friend3:->]);
        visit [-->];
    }
}

with entry {
    a = Person3(name="a");
    b = Person3(name="b");
    c = Person3(name="c");
    d = Person3(name="d");
    root ++> a;
    a +>:Friend3:+> b;
    a +>:Friend3:+> c;
    a +>:Block3:+> d;
    w = a spawn CountFriends();
    print(w.count);
}
'''
    },
    {
        "difficulty": "composed", "expected": "30",
        "py": '''
def sum_children(parent_vals: dict, parent: str, children: dict) -> int:
    """Sum the values of a parent's child nodes."""
    total = 0
    for child in children.get(parent, []):
        total += parent_vals[child]
    return total
''',
        "jac": '''
node Parent {
    has name: str;
}

node Child {
    has val: int;
}

walker SumChildren {
    has total: int = 0;

    can at_parent with Parent entry {
        visit [-->];
    }

    can at_child with Child entry {
        self.total += here.val;
    }
}

with entry {
    p = Parent(name="p");
    c1 = Child(val=10);
    c2 = Child(val=20);
    root ++> p;
    p ++> c1;
    p ++> c2;
    w = p spawn SumChildren();
    print(w.total);
}
'''
    },
    {
        "difficulty": "composed", "expected": "3",
        "py": '''
def last_value(chain: list) -> int:
    """Return the value of the last node in a chain."""
    return chain[-1]
''',
        "jac": '''
node TNode {
    has val: int;
}

walker LastValue {
    has last: int = 0;

    can chk with TNode entry {
        self.last = here.val;
        visit [-->];
    }
}

with entry {
    a = TNode(val=1);
    b = TNode(val=2);
    c = TNode(val=3);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn LastValue();
    print(w.last);
}
'''
    },
    {
        "difficulty": "composed", "expected": "6",
        "py": '''
def sum_name_lengths(tree: dict, start: str, names: dict) -> int:
    """Sum the lengths of all reachable node names."""
    total = 0
    stack = [start]
    while stack:
        node = stack.pop()
        total += len(names[node])
        stack.extend(tree.get(node, []))
    return total
''',
        "jac": '''
node Labelled {
    has name: str;
}

walker SumNameLen {
    has total: int = 0;

    can chk with Labelled entry {
        self.total += len(here.name);
        visit [-->];
    }
}

with entry {
    a = Labelled(name="ab");
    b = Labelled(name="cde");
    c = Labelled(name="f");
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn SumNameLen();
    print(w.total);
}
'''
    },
    {
        "difficulty": "composed", "expected": "True",
        "py": '''
def all_even(tree: dict, start: str, vals: dict) -> bool:
    """Return True if all reachable values are even."""
    stack = [start]
    while stack:
        node = stack.pop()
        if vals[node] % 2 != 0:
            return False
        stack.extend(tree.get(node, []))
    return True
''',
        "jac": '''
node ENode {
    has val: int;
}

walker AllEven {
    has ok: bool = True;

    can chk with ENode entry {
        if here.val % 2 != 0 {
            self.ok = False;
            disengage;
        }
        visit [-->];
    }
}

with entry {
    a = ENode(val=2);
    b = ENode(val=4);
    c = ENode(val=6);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn AllEven();
    print(w.ok);
}
'''
    },
    {
        "difficulty": "composed", "expected": "12",
        "py": '''
def product_leaves(tree: dict, start: str, vals: dict) -> int:
    """Multiply the values of leaf nodes."""
    result = 1
    stack = [start]
    while stack:
        node = stack.pop()
        children = tree.get(node, [])
        if not children:
            result *= vals[node]
        stack.extend(children)
    return result
''',
        "jac": '''
node Leaf3 {
    has val: int;
}

walker ProductLeaves {
    has result: int = 1;

    can chk with Leaf3 entry {
        if not [-->] { self.result *= here.val; }
        visit [-->];
    }
}

with entry {
    r1 = Leaf3(val=1);
    r2 = Leaf3(val=2);
    r3 = Leaf3(val=3);
    r4 = Leaf3(val=4);
    root ++> r1;
    r1 ++> r2;
    r1 ++> r3;
    r2 ++> r4;
    w = r1 spawn ProductLeaves();
    print(w.result);
}
'''
    },
    {
        "difficulty": "composed", "expected": "2",
        "py": '''
def count_below(tree: dict, start: str, vals: dict, threshold: int) -> int:
    """Count reachable nodes with value below threshold."""
    count = 0
    stack = [start]
    while stack:
        node = stack.pop()
        if vals[node] < threshold:
            count += 1
        stack.extend(tree.get(node, []))
    return count
''',
        "jac": '''
node BNode {
    has val: int;
}

walker CountBelow {
    has threshold: int;
    has count: int = 0;

    can chk with BNode entry {
        if here.val < self.threshold { self.count += 1; }
        visit [-->];
    }
}

with entry {
    a = BNode(val=3);
    b = BNode(val=7);
    c = BNode(val=2);
    d = BNode(val=9);
    root ++> a;
    a ++> b;
    b ++> c;
    c ++> d;
    w = a spawn CountBelow(threshold=5);
    print(w.count);
}
'''
    },
    {
        "difficulty": "composed", "expected": "5.0",
        "py": '''
def max_edge_weight(weights: list) -> float:
    """Return the largest edge weight on a path."""
    best = weights[0]
    for w in weights:
        if w > best:
            best = w
    return best
''',
        "jac": '''
node Stop3 {
    has name: str;
}

edge Link {
    has weight: float = 0.0;
}

walker MaxWeight {
    has best: float = 0.0;

    can step with Stop3 entry {
        for e in [edge -->] {
            if e.weight > self.best { self.best = e.weight; }
        }
        visit [-->];
    }
}

with entry {
    a = Stop3(name="a");
    b = Stop3(name="b");
    c = Stop3(name="c");
    root ++> a;
    a +>:Link(weight=2.0):+> b;
    b +>:Link(weight=5.0):+> c;
    w = a spawn MaxWeight();
    print(w.best);
}
'''
    },
    {
        "difficulty": "composed", "expected": "8",
        "py": '''
def sum_positive(tree: dict, start: str, vals: dict) -> int:
    """Sum only the positive reachable values."""
    total = 0
    stack = [start]
    while stack:
        node = stack.pop()
        if vals[node] > 0:
            total += vals[node]
        stack.extend(tree.get(node, []))
    return total
''',
        "jac": '''
node PNode {
    has val: int;
}

walker SumPositive {
    has total: int = 0;

    can chk with PNode entry {
        if here.val > 0 { self.total += here.val; }
        visit [-->];
    }
}

with entry {
    a = PNode(val=1);
    b = PNode(val=-2);
    c = PNode(val=3);
    d = PNode(val=4);
    root ++> a;
    a ++> b;
    b ++> c;
    c ++> d;
    w = a spawn SumPositive();
    print(w.total);
}
'''
    },
    {
        "difficulty": "composed", "expected": "3",
        "py": '''
def count_children(graph: dict, node: str) -> int:
    """Return the number of direct children of node."""
    return len(graph.get(node, []))
''',
        "jac": '''
node GNode {
    has name: str;
}

walker CountChildren {
    has count: int = 0;

    can chk with GNode entry {
        self.count = len([-->]);
        disengage;
    }
}

with entry {
    a = GNode(name="a");
    b = GNode(name="b");
    c = GNode(name="c");
    d = GNode(name="d");
    root ++> a;
    a ++> b;
    a ++> c;
    a ++> d;
    w = a spawn CountChildren();
    print(w.count);
}
'''
    },
    # ================= archetype / enum / static =================
    {
        "difficulty": "idiomatic", "expected": "3\n3",
        "py": '''
class Stack:
    """A stack with peek."""
    def __init__(self):
        self.items = []

    def push(self, x: int) -> None:
        self.items.append(x)

    def peek(self) -> int:
        return self.items[-1]

    def size(self) -> int:
        return len(self.items)
''',
        "jac": '''
obj Stack {
    has items: list[int] = [];

    def push(x: int) -> None { self.items.append(x); }

    def peek() -> int { return self.items[-1]; }

    def size() -> int { return len(self.items); }
}

with entry {
    s = Stack();
    s.push(1);
    s.push(2);
    s.push(3);
    print(s.peek());
    print(s.size());
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "GREEN",
        "py": '''
from enum import Enum


class Light(Enum):
    RED = "RED"
    GREEN = "GREEN"
    YELLOW = "YELLOW"


def next_light(l: Light) -> Light:
    """Advance a traffic light to its next state."""
    order = {Light.RED: Light.GREEN, Light.GREEN: Light.YELLOW, Light.YELLOW: Light.RED}
    return order[l]
''',
        "jac": '''
enum Light {
    RED = "RED",
    GREEN = "GREEN",
    YELLOW = "YELLOW"
}

def next_light(l: Light) -> Light {
    order: dict = {
        Light.RED: Light.GREEN,
        Light.GREEN: Light.YELLOW,
        Light.YELLOW: Light.RED
    };
    return order[l];
}

with entry {
    print(next_light(Light.RED).value);
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "25",
        "py": '''
class MathUtil:
    """Math helpers."""
    @staticmethod
    def square(x: int) -> int:
        return x * x
''',
        "jac": '''
obj MathUtil {
    static def square(x: int) -> int { return x * x; }
}

with entry {
    print(MathUtil.square(5));
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "24",
        "py": '''
class Box:
    """A rectangular box."""
    def __init__(self, w: int, h: int, d: int):
        self.w = w
        self.h = h
        self.d = d

    def volume(self) -> int:
        return self.w * self.h * self.d
''',
        "jac": '''
obj Box {
    has w: int;
    has h: int;
    has d: int;

    def volume() -> int { return self.w * self.h * self.d; }
}

with entry {
    b = Box(w=2, h=3, d=4);
    print(b.volume());
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "0",
        "py": '''
class Clock:
    """A 24-hour clock."""
    def __init__(self, hour: int):
        self.hour = hour

    def tick(self) -> None:
        self.hour = (self.hour + 1) % 24
''',
        "jac": '''
obj Clock {
    has hour: int;

    def tick() -> None { self.hour = (self.hour + 1) % 24; }
}

with entry {
    c = Clock(hour=23);
    c.tick();
    print(c.hour);
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "30",
        "py": '''
class Scoreboard:
    """Tracks the highest score seen."""
    def __init__(self):
        self.best = 0

    def submit(self, score: int) -> None:
        if score > self.best:
            self.best = score
''',
        "jac": '''
obj Scoreboard {
    has best: int = 0;

    def submit(score: int) -> None {
        if score > self.best { self.best = score; }
    }
}

with entry {
    sb = Scoreboard();
    sb.submit(10);
    sb.submit(30);
    sb.submit(20);
    print(sb.best);
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "[2, 1]",
        "py": '''
class Pair:
    """An ordered pair."""
    def __init__(self, a: int, b: int):
        self.a = a
        self.b = b

    def swapped(self) -> list:
        return [self.b, self.a]
''',
        "jac": '''
obj Pair {
    has a: int;
    has b: int;

    def swapped() -> list[int] { return [self.b, self.a]; }
}

with entry {
    p = Pair(a=1, b=2);
    print(p.swapped());
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "15",
        "py": '''
class RangeSum:
    """Sums an inclusive integer range."""
    def __init__(self, low: int, high: int):
        self.low = low
        self.high = high

    def total(self) -> int:
        return sum(range(self.low, self.high + 1))
''',
        "jac": '''
obj RangeSum {
    has low: int;
    has high: int;

    def total() -> int { return sum(range(self.low, self.high + 1)); }
}

with entry {
    rs = RangeSum(low=1, high=5);
    print(rs.total());
}
'''
    },
    {
        "difficulty": "idiomatic", "expected": "Hola, Bob",
        "py": '''
class Greeter:
    """Greets in a chosen language."""
    def __init__(self, greeting: str):
        self.greeting = greeting

    def greet(self, name: str) -> str:
        return self.greeting + ", " + name
''',
        "jac": '''
obj Greeter {
    has greeting: str;

    def greet(name: str) -> str { return self.greeting + ", " + name; }
}

with entry {
    g = Greeter(greeting="Hola");
    print(g.greet("Bob"));
}
'''
    },
    # ================= atomic-clean =================
    {
        "difficulty": "atomic", "expected": "6",
        "py": '''
def digital_root(n: int) -> int:
    """Repeatedly sum digits until a single digit remains."""
    while n >= 10:
        total = 0
        for ch in str(n):
            total += int(ch)
        n = total
    return n
''',
        "jac": '''
def digital_root(n: int) -> int {
    while n >= 10 {
        total = 0;
        for ch in str(n) { total += int(ch); }
        n = total;
    }
    return n;
}

with entry {
    print(digital_root(942));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "True\nFalse",
        "py": '''
def is_power_of_two(n: int) -> bool:
    """Return True if n is a power of two."""
    return n > 0 and (n & (n - 1)) == 0
''',
        "jac": '''
def is_power_of_two(n: int) -> bool {
    return n > 0 and (n & (n - 1)) == 0;
}

with entry {
    print(is_power_of_two(16));
    print(is_power_of_two(18));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "SWAP",
        "py": '''
def swap_case(s: str) -> str:
    """Swap the case of every letter."""
    return s.swapcase()
''',
        "jac": '''
def swap_case(s: str) -> str {
    return s.swapcase();
}

with entry {
    print(swap_case("swap"));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "banana",
        "py": '''
def longest_word(s: str) -> str:
    """Return the longest word in s."""
    best = ""
    for word in s.split():
        if len(word) > len(best):
            best = word
    return best
''',
        "jac": '''
def longest_word(s: str) -> str {
    best = "";
    for word in s.split() {
        if len(word) > len(best) { best = word; }
    }
    return best;
}

with entry {
    print(longest_word("i ate a banana"));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "24",
        "py": '''
def product(nums: list) -> int:
    """Return the product of a list of integers."""
    result = 1
    for n in nums:
        result *= n
    return result
''',
        "jac": '''
def product(nums: list[int]) -> int {
    result = 1;
    for n in nums { result *= n; }
    return result;
}

with entry {
    print(product([1, 2, 3, 4]));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "c",
        "py": '''
def first_non_repeating(s: str) -> str:
    """Return the first character that appears exactly once."""
    counts = {}
    for ch in s:
        counts[ch] = counts.get(ch, 0) + 1
    for ch in s:
        if counts[ch] == 1:
            return ch
    return ""
''',
        "jac": '''
def first_non_repeating(s: str) -> str {
    counts: dict[str, int] = {};
    for ch in s { counts[ch] = counts.get(ch, 0) + 1; }
    for ch in s {
        if counts[ch] == 1 { return ch; }
    }
    return "";
}

with entry {
    print(first_non_repeating("aabbc"));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "True",
        "py": '''
def is_perfect(n: int) -> bool:
    """Return True if n equals the sum of its proper divisors."""
    total = 0
    for i in range(1, n):
        if n % i == 0:
            total += i
    return total == n
''',
        "jac": '''
def is_perfect(n: int) -> bool {
    total = 0;
    for i in range(1, n) {
        if n % i == 0 { total += i; }
    }
    return total == n;
}

with entry {
    print(is_perfect(6));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "8",
        "py": '''
def collatz_steps(n: int) -> int:
    """Count the steps for n to reach 1 under the Collatz map."""
    steps = 0
    while n != 1:
        if n % 2 == 0:
            n //= 2
        else:
            n = 3 * n + 1
        steps += 1
    return steps
''',
        "jac": '''
def collatz_steps(n: int) -> int {
    steps = 0;
    while n != 1 {
        if n % 2 == 0 { n //= 2; }
        else { n = 3 * n + 1; }
        steps += 1;
    }
    return steps;
}

with entry {
    print(collatz_steps(6));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "10",
        "py": '''
def binary_to_int(bits: str) -> int:
    """Parse a binary string into an integer."""
    result = 0
    for ch in bits:
        result = result * 2 + int(ch)
    return result
''',
        "jac": '''
def binary_to_int(bits: str) -> int {
    result = 0;
    for ch in bits { result = result * 2 + int(ch); }
    return result;
}

with entry {
    print(binary_to_int("1010"));
}
'''
    },
    {
        "difficulty": "atomic", "expected": "3",
        "py": '''
def count_consonants(s: str) -> int:
    """Count the consonants in s."""
    count = 0
    for ch in s.lower():
        if ch.isalpha() and ch not in "aeiou":
            count += 1
    return count
''',
        "jac": '''
def count_consonants(s: str) -> int {
    count = 0;
    for ch in s.lower() {
        if ch.isalpha() and ch not in "aeiou" { count += 1; }
    }
    return count;
}

with entry {
    print(count_consonants("hello"));
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
