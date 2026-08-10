"""Parse elapsed time strings such as 11:27, 21:42:39, or 1-20:21:50."""
def parse_elapsed_time_string(dstr: str) -> int | None {
    dy = 0;
    hr = 0;
    mn = 0;
    sc = 0;
    sL = dstr.split('-', 1);
    if len(sL) == 1 {
        hms = dstr;
    } else {
        try {
            dy = int(sL[0]);
            hms = sL[1];
        } except Exception {
            return None;
        }
    }
    nL = hms.split(':');
    try {
        sc = int(nL[-1]);
        if sc < 0 or sc >= 60 {
            return None;
        }
    } except Exception {
        return None;
    }
    if len(nL) > 1 {
        try {
            mn = int(nL[-2]);
            if mn < 0 or mn >= 60 {
                return None;
            }
        } except Exception {
            return None;
        }
    }
    if len(nL) > 2 {
        try {
            hr = int(nL[-3]);
            if hr < 0 or hr > 24 {
                return None;
            }
        } except Exception {
            return None;
        }
    }
    return (dy * 24 * 60 * 60) + (hr * 60 * 60) + (mn * 60) + sc;
}