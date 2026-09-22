"""Get the bucket name to be used for historical alert retention."""
def firehose_alerts_bucket(config: dict[str, dict[str, dict[str, dict[str, str]]]]) -> str {
    return config['global']['infrastructure'].get('alerts_firehose', {}).get(
        'bucket_name', '{}-streamalerts'.format(config['global']['account']['prefix'])
    );
}