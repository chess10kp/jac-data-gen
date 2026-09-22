"""
Parse dataset slice

Parameters
----------
ds_slice : tuple | int | slice | list
    Slice to extract from dataset

Returns
-------
ds_slice : tuple
    slice for axis (0, 1)
"""
def parse_slice(ds_slice: tuple | int | slice | list) -> tuple {
    if not isinstance(ds_slice, tuple) {
        ds_slice = (ds_slice, );
    }
    return ds_slice;
}