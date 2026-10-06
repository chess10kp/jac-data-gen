"""Type definitions for appointment and care gap tracking."""

enum AppointmentStatus {
    SCHEDULED,
    COMPLETED,
    CANCELLED,
    NO_SHOW,
    NEEDS_RESCHEDULE,
    RESCHEDULE_QUEUED
}

enum AppointmentType {
    IN_PERSON,
    TELEHEALTH,
    PHONE,
    HOME_VISIT
}

enum CareGapType {
    PCP,
    DENTAL,
    VISION,
    SPECIALIST,
    MAMMOGRAM,
    COLONOSCOPY,
    BONE_DENSITY,
    DIABETES_SCREENING,
    BLOOD_PRESSURE,
    CHOLESTEROL,
    INFLUENZA_VACCINE,
    PNEUMONIA_VACCINE,
    SHINGLES_VACCINE
}

enum CareGapSeverity {
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL
}
