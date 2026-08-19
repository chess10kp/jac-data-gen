walker:pub ready {
    can check with Root entry {
        db_ok = self.safe_check(check_database);
        cache_ok = self.safe_check(check_cache);

        if db_ok and cache_ok {
            report {"status": "ready"};
        } else {
            report {"status": "not_ready", "db": db_ok, "cache": cache_ok};
        }
    }

    def safe_check(probe: object) -> bool {
        try {
            return bool(probe());
        } except Exception {
            return False;
        }
    }
}
