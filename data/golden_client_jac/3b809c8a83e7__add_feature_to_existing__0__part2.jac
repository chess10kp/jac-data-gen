import threading;

obj ReadWriteLock {
    has _cond: threading.Condition by postinit,
        _readers: int = 0,
        _writer: bool = False;

    def postinit -> None;
    def acquire_read -> None;
    def release_read -> None;
    def acquire_write -> None;
    def release_write -> None;
}

impl ReadWriteLock.postinit -> None {
    self._cond = threading.Condition(threading.Lock());
}

impl ReadWriteLock.acquire_read -> None {
    with self._cond {
        while self._writer {
            self._cond.wait();
        }
        self._readers += 1;
    }
}

impl ReadWriteLock.release_read -> None {
    with self._cond {
        self._readers -= 1;
        if self._readers == 0 {
            self._cond.notify_all();
        }
    }
}

impl ReadWriteLock.acquire_write -> None {
    with self._cond {
        while self._writer or self._readers > 0 {
            self._cond.wait();
        }
        self._writer = True;
    }
}

impl ReadWriteLock.release_write -> None {
    with self._cond {
        self._writer = False;
        self._cond.notify_all();
    }
}
