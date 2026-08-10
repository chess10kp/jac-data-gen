"""Returns a list of normalized kvstore entries."""
def normalized(name: Any, feed_entries: Any, start: Any) -> object {
    data = [];
    for feed_entry in feed_entries {
        if (('indicator' not in feed_entry) or ('value' not in feed_entry)) {
            continue;
        }
        `entry = feed_entry.copy();
        `entry['splunk_source'] = name;
        `entry['splunk_last_seen'] = start;
        data.append(`entry);
    }
    return data;
}