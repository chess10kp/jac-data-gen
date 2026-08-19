node Item {
    has price: int;
}

with entry {
    root ++> Item(price=5);
    root ++> Item(price=50);
    cheap = [root --> ][?price < 10];
    print(len(cheap));
}

with entry {
    x = root;
    print(x);
}

import from os { path }

with entry {
    print(path.join("a", "b"));
}
