with entry {
    storage = store();

    # Generate a URL that expires in 10 minutes (600 seconds)
    # For S3, this is a pre-signed URL.
    url = storage.get_url("profile-photos/user1.jpg", expires_in=600);
}

walker :pub download_file {
    has path: str;

    can process with Root entry {
        if not storage.exists(self.path) {
            report {"error": "File not found"};
            return;
        }
        content = storage.download(self.path);
        report {"content": content, "size": len(content)};
    }
}
