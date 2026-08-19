import type from billing { Invoice }

def total(inv: Invoice) -> int {
    return inv.amount;
}
