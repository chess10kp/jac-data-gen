"""Type definitions for bill tracking, subscriptions, and benefit programs."""

enum BillCategory {
    UTILITY,
    INSURANCE,
    SUBSCRIPTION,
    MEDICAL,
    HOUSING,
    PHONE,
    INTERNET,
    TRANSPORTATION,
    OTHER
}

enum SubscriptionClassification {
    ESSENTIAL,
    USEFUL,
    WASTEFUL,
    UNKNOWN,
    CANCELLATION_QUEUED,
    CANCELLED
}

enum PaymentStatus {
    CURRENT,
    DUE_SOON,
    OVERDUE,
    PAID,
    MISSED,
    ON_AUTOPAY
}

enum BenefitProgram {
    EXTRA_HELP,
    QMB,
    SLMB,
    SNAP,
    LIHEAP,
    MEDICARE_SAVINGS_PROGRAM,
    STATE_PHARMACEUTICAL_ASSISTANCE,
    MEDICAID,
    VETERANS_BENEFITS,
    SUPPLEMENTAL_SECURITY_INCOME
}

enum EligibilityStatus {
    LIKELY_ELIGIBLE,
    INELIGIBLE,
    NEEDS_REVIEW,
    APPLIED,
    ENROLLED,
    DENIED
}
