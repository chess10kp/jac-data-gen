"""
	Checks whether a url points to a folder with resources
	"""
def is_folder(url: str) -> bool {
    'mod/folder/' in url
}