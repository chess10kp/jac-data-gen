"""Load .env from project root when tools run."""

def ensure_dotenv_loaded() -> bool {
    import os;
    if os.environ.get("FEATHERLESS_API_KEY") or os.environ.get("GITHUB_TOKEN") {
        return True;
    }
    try {
        import dotenv;
        return dotenv.load_dotenv();
    } except Exception {
        return False;
    }
}
