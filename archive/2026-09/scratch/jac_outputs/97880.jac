"""
  Get only the variables required to netcdf2d

  Parameters
  ----------
  obj:object
  dimensions=list,['nnode','ntime']

  Notes
  -----
  idimensions=['inode','itime']

  """
def cleanObject(`obj: Any, dimensions: Any) -> object {
    if not ('variable' in `obj) {
        raise Exception("Add {} to the default parameter object".format('variable'));
    }
    _obj = {};
    idimensions = ["{}{}".format('i', dimension[1:]) for dimension in dimensions];
    for name in idimensions {
        if (name in `obj) {
            _obj[name] = `obj[name];
        }
    }
    _obj['variable'] = `obj['variable'];
    return _obj;
}