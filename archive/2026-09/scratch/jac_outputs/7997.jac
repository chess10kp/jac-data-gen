"""
    Format data for bulk indexing into elasticsearch
    """
def format_data(data: Any, es_index: Any) -> object {
    unit = data["unit"];
    rate_unit = data["rateUnit"];
    egvs = data["egvs"];
    docs = [];
    for record in egvs {
        record["unit"] = unit;
        record["rate_unit"] = rate_unit;
        record["@timestamp"] = record.pop("systemTime");
        record.pop("displayTime");
        record["realtime_value"] = record.pop("realtimeValue");
        record["smoothed_value"] = record.pop("smoothedValue");
        record["trend_rate"] = record.pop("trendRate");
        docs.append({"_index": es_index, "_type": "document", "_source": record});
    }
    return docs;
}