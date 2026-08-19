enum Status {
    PENDING = "pending",
    ACTIVE = "active",
    COMPLETED = "completed",
    CANCELLED = "cancelled"
}

with entry {
    s = Status.COMPLETED;
    print(s.value);
}
