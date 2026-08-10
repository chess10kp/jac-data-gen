"""Accept also incomplete name to zip file only"""
def isMetaLogName(filename: str) -> bool {
    return 'meta_' in filename or filename.endswith('.zip');
}