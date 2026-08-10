""" Replaces cell type with max celltype in anndata object, but preserves original call if no max cell type is found. """
def replace_celltypes(celldict: Any, row: Any, label: Any) -> object {
    if (row['leiden'] in celldict) {
        return celldict[row['leiden']];
    } else {
        return row[label];
    }
}