def readAllEntries(reader: any) -> any {
    return new(Promise, lambda(resolve: any, reject: any) {
        allEntries: list = [];

        def readBatch() -> None {
            reader.readEntries(
                lambda(entries: any) {
                    if not entries or entries.length == 0 {
                        resolve.call(None, allEntries);
                    } else {
                        for e in entries {
                            allEntries.push(e);
                        }
                        readBatch();
                    }
                },
                lambda(err: any) { reject.call(None, err); }
            );
        }
        readBatch();
    });
}
