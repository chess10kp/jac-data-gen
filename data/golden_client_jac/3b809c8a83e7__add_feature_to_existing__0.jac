impl ReadWriteLock.acquire_write -> None {
    with self._cond {
        self._writer = True;
    }
}

impl ReadWriteLock.release_write -> None {
    with self._cond {
        self._writer = False;
    }
}
