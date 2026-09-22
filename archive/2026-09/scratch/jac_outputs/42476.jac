"""
	checks if colnames are comaptible with provided list

	:param ds: ds header name
	:param file: lsit of allowed header names

	:return: bool showing whether given colname is compatible with list
	"""
def valid_cluster_header(ds: Any, file: Any) -> object {
    return (str(ds) in list(file));
}