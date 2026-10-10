"""Stockroom: Item nodes with a Movement node per successful adjustment."""

node Item {
    has sku: str;
    has quantity: int = 0;
}

node Movement {
    has delta: int;
    has reason: str = "";
}

walker:pub adjust_stock {
    has sku: str;
    has delta: int;
    has reason: str = "";

    can adjust with Root entry {
        code = self.sku.strip().upper();
        found = [i for i in [here -->[?:Item]] if i.sku == code];
        if not found {
            if self.delta <= 0 {
                report {"error": "unknown sku", "quantity": 0};
                return;
            }
            item = here ++> Item(sku=code, quantity=0);
        } else {
            item = found[0];
        }
        if item.quantity + self.delta < 0 {
            report {"error": "insufficient stock", "quantity": item.quantity};
            return;
        }
        item.quantity += self.delta;
        item ++> Movement(delta=self.delta, reason=self.reason);
        report {"sku": item.sku, "quantity": item.quantity, "movements": len([item -->[?:Movement]])};
    }
}

test "receive then use" {
    a = (root spawn adjust_stock(sku="unit-chain", delta=5)).reports[0];
    b = (root spawn adjust_stock(sku="UNIT-CHAIN", delta=-2, reason="repair")).reports[0];
    assert b["quantity"] == a["quantity"] - 2;
    assert b["movements"] == a["movements"] + 1;
}

test "cannot go negative" {
    root spawn adjust_stock(sku="unit-tube", delta=1);
    r = (root spawn adjust_stock(sku="unit-tube", delta=-1000)).reports[0];
    assert r["error"] == "insufficient stock";
}
