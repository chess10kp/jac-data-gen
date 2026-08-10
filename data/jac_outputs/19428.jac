"""Return the file name minus the trailing suffix."""
def getFileNameOnly(fileName: str) -> str {
    '.'.join(fileName.split('/')[-1].split('.')[:-1])
}