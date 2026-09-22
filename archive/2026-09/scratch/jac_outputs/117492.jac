"""
        ICD9
            331.83 Mild cognitive impairment, so stated
            294.9	 Unspecified persistent mental disorders due to conditions classified elsewhere
        ICD10
            G31.84 Mild cognitive impairment, so stated
            F09	Unspecified mental disorder due to known physiological condition
     """
def is_mci(code: str) -> bool {
    assert isinstance(code, str);
    code_set = ('331.83', '294.9', 'G31.84', 'F09', '33183', '2949', 'G3184');
    return code.startswith(code_set);
}