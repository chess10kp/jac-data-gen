"""Helper to extract meta values from a Celery Context"""
def tags_from_context(context: dict[str, object]) -> dict[str, object] {
    tag_keys = (
        'compression',
        'correlation_id',
        'countdown',
        'delivery_info',
        'eta',
        'exchange',
        'expires',
        'hostname',
        'id',
        'priority',
        'queue',
        'reply_to',
        'retries',
        'routing_key',
        'serializer',
        'timelimit',
        'origin',
        'state'
    );
    tags: dict[str, object] = {};
    for key in tag_keys {
        value = context.get(key);
        if value is None or value == '' {
            continue;
        }
        if key == 'timelimit' and value in [(None, None), [None, None]] {
            continue;
        }
        if key == 'retries' and value == 0 {
            continue;
        }
        if key == 'origin' {
            key = 'hostname';
        }
        tags[f'celery.{key}'] = value;
    }
    return tags;
}