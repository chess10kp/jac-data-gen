import from jac_scale.lib { kvstore }

with entry {
    cache = kvstore(db_name='cache', db_type='redis');

    cache.set('session:user123', {'user_id': '123', 'username': 'alice'});
    cache.set_with_ttl('temp:token', {'token': 'xyz'}, ttl=60);
    cache.set_with_ttl('cache:profile', {'name': 'Alice'}, ttl=3600);

    cache.incr('stats:views');
    sessions = cache.scan_keys('session:*');
    cache.expire('session:user123', 1800);
}
