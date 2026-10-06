"""Medical code type helpers and constants."""

# CMS place-of-service codes (POS)
glob POS_CODES: dict = {
    "11": "Office",
    "12": "Home",
    "21": "Inpatient Hospital",
    "22": "On Campus-Outpatient Hospital",
    "23": "Emergency Room - Hospital",
    "24": "Ambulatory Surgical Center",
    "31": "Skilled Nursing Facility",
    "32": "Nursing Facility",
    "33": "Custodial Care Facility",
    "34": "Hospice",
    "41": "Ambulance - Land",
    "51": "Inpatient Psychiatric Facility",
    "65": "End-Stage Renal Disease Treatment Facility",
    "81": "Independent Laboratory"
};
# Common revenue codes (UB-04)
glob REVENUE_CODES: dict = {
    "0100": "All-Inclusive Rate",
    "0110": "Room & Board - Private",
    "0120": "Room & Board - Semi-Private",
    "0200": "ICU - General",
    "0250": "Pharmacy",
    "0270": "Medical/Surgical Supplies",
    "0300": "Laboratory",
    "0350": "CT Scan",
    "0360": "Operating Room Services",
    "0450": "Emergency Room",
    "0500": "Ambulatory Surgery",
    "0510": "Outpatient Services",
    "0636": "Drugs requiring detailed coding",
    "0710": "Recovery Room"
};
# Type of bill codes (first digit = facility, second = care type, third = claim frequency)
glob TOB_FACILITY: dict = {
    "1": "Hospital",
    "2": "Skilled Nursing Facility",
    "3": "Home Health Agency",
    "4": "Religious Non-Medical Health Care Institution",
    "5": "Intermediate Care",
    "6": "Clinic",
    "7": "Clinic - Dialysis Outpatient",
    "8": "Special Facility"
};
# Standard modifier descriptions
glob MODIFIER_DESC: dict = {
    "25": "Significant, Separately Identifiable E/M",
    "26": "Professional Component",
    "TC": "Technical Component",
    "50": "Bilateral Procedure",
    "51": "Multiple Procedures",
    "52": "Reduced Services",
    "53": "Discontinued Procedure",
    "54": "Surgical Care Only",
    "55": "Postoperative Management Only",
    "56": "Preoperative Management Only",
    "57": "Decision for Surgery",
    "58": "Staged/Related Procedure",
    "59": "Distinct Procedural Service",
    "GA": "Waiver of Liability Statement on File",
    "GY": "Item/Service Statutorily Excluded",
    "GZ": "Item/Service Expected to be Denied",
    "LT": "Left Side",
    "RT": "Right Side",
    "QW": "CLIA Waived Test",
    "XE": "Separate Encounter",
    "XP": "Separate Practitioner",
    "XS": "Separate Structure",
    "XU": "Unusual Non-Overlapping Service"
};