"""
Checks whether checked version is higher or equal to given min version
"""
def version_check(checked_version: str | None, min_version: str) -> bool {
    def version_transform(ver: str | None) -> str {
        version = '';
        vn = '';
        va = '';
        stage = 0;
        ver = '.' + (ver or '');
        for c in ver {
            if c == '.' {
                if vn or va {
                    version += '{0:0>3}{1: <2}.'.format(vn, va);
                }
                vn = '';
                va = '';
                stage = 0;
                continue;
            }
            if c.isdigit() {
                ;
            } elif c.isalpha() {
                stage = max(1, stage);
            } else {
                stage = max(2, stage);
            }
            if stage == 0 {
                vn += c;
            } elif stage == 1 {
                va += c;
            }
        }
        if vn or va {
            version += '{0:0>3}{1: <2}.'.format(vn, va);
        }
        return version[:-1];
    }
    if not checked_version {
        return False;
    }
    return version_transform(checked_version) >= version_transform(min_version);
}