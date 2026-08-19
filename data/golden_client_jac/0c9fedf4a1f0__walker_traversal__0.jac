import from http { UploadFile }
import from uuid { uuid4 }

glob storage = store(base_path="./uploads");

walker :pub upload_file {
    has file: UploadFile;
    has folder: str = "documents";

    can process with Root entry {
        unique_name = f"{uuid4()}.dat";
        path = f"{self.folder}/{unique_name}";

        # Upload file
        storage.upload(self.file.file, path);

        # Get metadata
        metadata = storage.get_metadata(path);

        report {
            "success": True,
            "storage_path": path,
            "size": metadata["size"]
        };
    }
}

walker :pub list_files {
    has folder: str = "documents";
    has recursive: bool = False;

    can process with Root entry {
        files = [];
        for path in storage.list_files(self.folder, self.recursive) {
            metadata = storage.get_metadata(path);
            files.append({
                "path": path,
                "size": metadata["size"],
                "name": metadata["name"]
            });
        }
        report {"files": files};
    }
}
