"""Computes refundable retirement savings tax credit amount."""
def IRADCTaxCredit(
    e03150: float, e03300: float, IRADC_credit_c: float, IRADC_credit_rt: float, iradctc: float
) -> float {
    tot_retirement_contributions = e03150 + e03300;
    if IRADC_credit_rt > 0.0 {
        iradctc = min(tot_retirement_contributions * IRADC_credit_rt, IRADC_credit_c);
    } else {
        iradctc = 0.0;
    }
    return iradctc;
}