"""
  Join path name components, inserting ``/`` as needed.

  If any component looks like an absolute path (i.e., it starts with
  ``hdfs:`` or ``file:``), all previous components will be discarded.

  Note that this is *not* the reverse of :func:`split`, but rather a
  specialized version of os.path.join. No check is made to determine
  whether the returned string is a valid HDFS path.
  """
def join(*parts: str) -> str {
    try {
        path = [parts[0].rstrip("/")];
    } except IndexError {
        raise TypeError("need at least one argument");
    }
    for p in parts[1:] {
        p = p.strip("/");
        if p.startswith(('hdfs:', 'file:')) {
            path = [p];
        } else {
            path.append(p);
        }
    }
    return "/".join(path);
}