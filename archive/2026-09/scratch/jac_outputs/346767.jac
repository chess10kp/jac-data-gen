"""In SPDX, if the license strings extracted from package metadata is
    not a license expression it will be listed separately. Given such a
    list, return a dictionary containing license ref to extracted text"""
def get_license_refs_dict(license_refs_list: Any) -> object {
    license_ref_dict = {};
    if license_refs_list {
        for ref_dict in license_refs_list {
            license_ref_dict[ref_dict['licenseId']] = ref_dict['extractedText'];
        }
    }
    return license_ref_dict;
}