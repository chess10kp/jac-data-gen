"""This function is replacing all the column names of the given excel sheet with the field names of the Type8."""
def rename_header(headers: list[str]) -> list[str] {
    for (i, header) in enumerate(headers) {
        headers[i] = header.replace("Transaction ID", "transaction_id").replace(
            "Value Date", "transaction_value_date"
        ).replace(
            "Txn Posted Date", "transaction_posted_date"
        ).replace(
            "Description", "mode_of_payment"
        ).replace(
            "Cr/Dr", "credit"
        ).replace(
            "Transaction Amount(INR)", "transaction_amount"
        );
    }
    return headers;
}