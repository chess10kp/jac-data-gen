import os;

walker get_config {
    can fetch with Root entry {
        report {
            "database_url": os.getenv("DATABASE_URL", "sqlite:///default.db"),
            "api_key_configured": os.getenv("API_KEY") is not None,
            "debug": os.getenv("DEBUG", "false") == "true"
        };
    }
}
