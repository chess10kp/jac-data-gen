tramway.jac: the `_ride` helper walks a line with a while loop, grabbing the next stop by hand and stuffing route/minutes/looped into a dict. this is exactly what walkers are for — please replace it with a walker you spawn on the start stop that follows only that line's tracks and stops when the line ends or comes back round. drop the dict.

add_hop / ride / ride_minutes / is_loop stay as they are (same args, same results).
