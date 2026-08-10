"""Return whether the file is not the clusterserviceversion (csv) file."""
def is_not_csv_file(filename: str) -> bool {
    return not filename.endswith('clusterserviceversion.yaml');
}