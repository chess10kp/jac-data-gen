"""A cron trigger as a dictionary."""
def date_trigger_dict(ts_epoch: Any) -> object {
    return {'run_date': ts_epoch, 'timezone': 'utc'};
}