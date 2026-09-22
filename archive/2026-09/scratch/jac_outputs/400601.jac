"""Construct the arguments for declaring a queue.

    If the rabbit_ha_queues option is set, we try to declare a mirrored queue
    as described here:

      http://www.rabbitmq.com/ha.html

    Setting x-ha-policy to all means that the queue will be mirrored
    to all nodes in the cluster. In RabbitMQ 3.0, queue mirroring is
    no longer controlled by the x-ha-policy argument when declaring a
    queue. If you just want to make sure that all queues (except those
    with auto-generated names) are mirrored across all nodes, run:
      rabbitmqctl set_policy HA '^(?!amq\.).*' '{"ha-mode": "all"}'

    If the rabbit_queue_ttl option is > 0, then the queue is
    declared with the "Queue TTL" value as described here:

      https://www.rabbitmq.com/ttl.html

    Setting a queue TTL causes the queue to be automatically deleted
    if it is unused for the TTL duration.  This is a helpful safeguard
    to prevent queues with zero consumers from growing without bound.
    """
def _get_queue_arguments(rabbit_ha_queues: bool, rabbit_queue_ttl: int) -> dict[str, str | int] {
    args: dict[str, str | int] = {};
    if rabbit_ha_queues {
        args['x-ha-policy'] = 'all';
    }
    if rabbit_queue_ttl > 0 {
        args['x-expires'] = rabbit_queue_ttl * 1000;
    }
    return args;
}