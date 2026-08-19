with entry{
    db = kvstore(db_name='jac_db', db_type='mongodb');
    young_users = list(db.find_nodes('User', {'age': {'$lt': 30}}));
    admins = list(db.find_nodes('User', {'role': 'admin'}));
}
