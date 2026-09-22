"""
If you set View Scope, the computing time of algorithm will be reduced.
But the side effect is that maybe you don't know what the best view scope for each patient's case.
There is some patient's case that is not scanned in middle position. So finally, I think return
512x512 is the best value because pixel_array in CT is 512x512 size.
"""
def get_view_scope_by_dicom_dict(dicom_dict: dict[str, object]) -> tuple[int, int, int, int] {
    (0, 512, 0, 512)
}