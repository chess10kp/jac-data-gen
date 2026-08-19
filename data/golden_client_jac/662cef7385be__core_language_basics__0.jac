import from jac_scale.lib { kvstore }

with entry {
    mongo_db = kvstore(db_name='my_app', db_type='mongodb');
    redis_db = kvstore(db_name='cache', db_type='redis');
}
