import from typing { IO }

"""Get the size of a shard."""
def get_size(shard: IO) -> int {
    shard.seek(0, 2);
    return shard.tell();
}