"""Seed numpy before calling worker_init_fn."""
def _seed_npy_before_worker_init(
    worker_id: int,
    seed: int,
    worker_init_fn: Callable[[int], int | None] | None = None
) -> int | None {
    try {
        import numpy as np;
        np.random.seed(seed + worker_id);
    } except ImportError {
        ;
    }
    if worker_init_fn is not None {
        return worker_init_fn(worker_id);
    }
}