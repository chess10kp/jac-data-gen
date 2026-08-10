"""
function to set the default value for projectNameOption

Args:
    projectNameOption: name for the project directory (root directory)

Returns: name for the project directory
"""
def checkProjectNameOption(projectNameOption: str | None) -> str {
    return projectNameOption if projectNameOption is not None else 'RAAD';
}