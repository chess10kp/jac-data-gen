"""
Checks if parameter is output parameter.
Returns True if parameter has key 'gisprompt.age' == 'new',
False otherwise.
"""
def isOutput(parameter: dict[str, dict[str, str]]) -> bool {
    try {
        if '@age' in parameter['gisprompt'].keys() {
            return parameter['gisprompt']['@age'] == 'new';
        }
        return False;
    } except KeyError {
        return False;
    }
}