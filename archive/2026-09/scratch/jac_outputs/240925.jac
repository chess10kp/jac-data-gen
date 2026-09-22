"""Return the sector size of a partition.
Used by disk_io_counters().
"""
def get_sector_size(partition: str) -> int {
    try {
        with open(("/sys/block/%s/queue/hw_sector_size" % partition), "rt") as f {
            return int(f.read());
        }
    } except (IOError, ValueError) {
        return 512;
    }
}