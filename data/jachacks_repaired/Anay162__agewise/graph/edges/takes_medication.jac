"""takes_medication edge — Patient takes a Medication."""

edge takes_medication {
    has start_date: str = "",
        end_date: str = "",
        active: bool = True,
        prescribed_by_npi: str = "";
}