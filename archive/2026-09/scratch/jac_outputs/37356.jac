"""Format the missed datasets record we got from the database to adhere to the response schema."""
def transform_misses(record: dict[str, str]) -> dict[str, str | int | bool | dict[str, str | None] | None] {
    response: dict[str, str | int | bool | dict[str, str | None] | None] = {};
    response["datasetId"] = dict(record).get("stableId");
    response["internalId"] = dict(record).get("datasetId");
    response["exists"] = False;
    response["variantCount"] = 0;
    response["callCount"] = 0;
    response["sampleCount"] = 0;
    response["frequency"] = 0;
    response["numVariants"] = 0;
    response["info"] = {"access_type": dict(record).get("accessType")};
    return response;
}