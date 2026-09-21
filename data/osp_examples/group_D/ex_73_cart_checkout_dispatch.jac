"""Shopping-cart checkout with subtype dispatch over product types.

The cart holds books, electronics and clothing through Contains edges
carrying quantities. One pricing ability handles every product: typed
context blocks dispatch on the concrete subtype to apply type-specific
rules (digital books ship free, electronics pay a handling fee, clothing
ships free only over a threshold), and the finished receipt prints when
the walker exits the cart.
"""

node Product {
    has sku: str;
    has unit_price: float;
}

node Book(Product) {
    has title: str;
    has author: str;
    has fmt: str = "paper";  # "paper" | "digital"
}

node Electronics(Product) {
    has model: str;
    has warranty_years: int = 1;
}

node Clothing(Product) {
    has label: str;
    has size: str = "M";
}

node Cart {
    has owner: str;
}

edge Contains: Cart --> Product {
    has qty: int = 1;
}

walker Checkout {
    has qtys: list[int] = [];   # quantity per product, in visit order
    has cursor: int = 0;
    has subtotal: float = 0.0;
    has shipping: float = 0.0;
    has receipt: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can enter_cart with Cart entry {
        lines = [edge ->:Contains:->];
        for ln in lines {
            self.qtys.append(ln.qty);
        }
        visit [->:Contains:->];
    }

    can price_item with Product entry {
        qty = self.qtys[self.cursor];
        self.cursor += 1;

        line_total = 0.0;
        line_ship = 0.0;
        desc = "";

        # Dispatch on the concrete subtype; isinstance narrows the
        # static type so subtype-specific fields are readable.
        ->Book{
            if isinstance(here, Book) {
                bk = here;
                line_total = bk.unit_price * qty;
                if bk.fmt == "digital" {
                    desc = f"{bk.title} (digital) x{qty}";
                } else {
                    desc = f"{bk.title} (paper) x{qty}";
                    line_ship = 2.0 * qty;
                }
            }
        }
        ->Electronics{
            if isinstance(here, Electronics) {
                gadget = here;
                line_total = gadget.unit_price * qty;
                desc = f"{gadget.model} ({gadget.warranty_years}yr warranty) x{qty}";
                line_ship = 4.99;
            }
        }
        ->Clothing{
            if isinstance(here, Clothing) {
                wear = here;
                line_total = wear.unit_price * qty;
                desc = f"{wear.label} size {wear.size} x{qty}";
                if line_total < 100.0 {
                    line_ship = 5.99;
                }
            }
        }

        self.subtotal += line_total;
        self.shipping += line_ship;
        line = desc;
        self.receipt.append(f"{line:<42} ${round(line_total, 2):>7}");
    }

    can finish with Cart exit {
        # Deferred until every item in the cart has been priced.
        print(f"Receipt for {here.owner}:");
        for row in self.receipt {
            print(f"  {row}");
        }
        total = self.subtotal + self.shipping;
        print(f"  {'SUBTOTAL':<42} ${round(self.subtotal, 2):>7}");
        print(f"  {'SHIPPING':<42} ${round(self.shipping, 2):>7}");
        print(f"  {'TOTAL':<42} ${round(total, 2):>7}");
    }
}

with entry {
    for stale in [root -->][?:Cart] {
        del stale;
    }

    cart = Cart(owner="Taylor");

    cart +>: Contains(qty=1) :+> Book(
        sku="BK-101", unit_price=18.5,
        title="Spatial Walkways", author="R. Vega", fmt="paper",
    );
    cart +>: Contains(qty=2) :+> Book(
        sku="BK-102", unit_price=9.99,
        title="Graphs All the Way Down", author="M. Chen", fmt="digital",
    );
    cart +>: Contains(qty=1) :+> Electronics(
        sku="EL-77", unit_price=349.0,
        model="PathFinder GPS", warranty_years=3,
    );
    cart +>: Contains(qty=3) :+> Clothing(
        sku="CL-42", unit_price=12.0,
        label="Trail Socks", size="L",
    );

    root ++> cart;
    root spawn Checkout();
}
