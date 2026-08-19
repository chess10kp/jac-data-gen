glob storage = store();

walker :pub download_file {
    has path: str;
    has expires_in: int = 600;

    can process with Root entry {
        if not storage.exists(self.path) {
            report {"error": "File not found"};
            return;
        }
        # Hand back a time-limited URL; the client fetches bytes directly
        # from storage instead of round-tripping them through this JSON body.
        url = storage.get_url(self.path, expires_in=self.expires_in);
        report {"url": url, "expires_in": self.expires_in};
    }
}
