"""Return who the payor is depends on the monthly amount from Factsheet C."""
def child_support_payor_c(responses: dict[str, str | int | float], derived: dict[str, object]) -> str {
    try {
        amount_1 = float(responses.get('your_child_support_paid_c', 0));
    } except ValueError {
        amount_1 = 0;
    }
    try {
        amount_2 = float(responses.get('your_spouse_child_support_paid_c', 0));
    } except ValueError {
        amount_2 = 0;
    }
    if amount_1 > amount_2 {
        payor = 'you';
    } elif amount_1 < amount_2 {
        payor = 'spouse';
    } else {
        payor = 'both';
    }
    return payor;
}