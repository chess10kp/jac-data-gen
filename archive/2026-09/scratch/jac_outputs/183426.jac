"""Parses checkpoint string to get iteration."""
def parse_checkpoint(ckpt: str) -> int {
    assert type(ckpt) == str, ckpt;
    try {
        i = int(ckpt.split('_')[-1].split('.')[0]);
    } except Exception {
        print('unknown checkpoint string format %s setting iteration to 0' % ckpt);
        i = 0;
    }
    return i;
}