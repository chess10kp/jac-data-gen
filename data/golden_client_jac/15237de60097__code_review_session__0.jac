def check_database() -> bool { return True; }
def check_cache() -> bool { return True; }

walker:pub ready {
    can check with Root entry {
        db_ok = check_database();
        cache_ok = check_cache();
        if db_ok and cache_ok {
            report {"status": "ready"};
        } else {
            report {"status": "not_ready", "db": db_ok, "cache": cache_ok};
        }
    }
}
