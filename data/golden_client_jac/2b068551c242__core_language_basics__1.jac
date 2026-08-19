import from jac_scale.lib { kvstore }

with entry {
    db = kvstore(db_name='my_app', db_type='mongodb');

    db.insert_one('users', {'name': 'Alice', 'role': 'admin', 'age': 30});
    alice = db.find_one('users', {'name': 'Alice'});
    admins = list(db.find('users', {'role': 'admin'}));
    older = list(db.find('users', {'age': {'$gt': 28}}));

    db.update_one('users', {'name': 'Alice'}, {'$set': {'age': 31}});
    db.delete_one('users', {'name': 'Bob'});

    db.set('user:123', {'status': 'active'}, 'sessions');
}
