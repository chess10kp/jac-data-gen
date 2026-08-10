""" Returns the forward euler approximation of the change in `y` over the
        timestep `dt`

        Parameters
        ----------
        f (callable): accepts `y`, `t` and all of the parameters in `params`
        y (ndarray or float): current system state
        t (float): time value
        dt (float): timestep size
        params (tuple): Tuple of parameters for `f`

        Returns
        -------
        dy (ndarray or float): approximation of the change in `y`
            over the timestep `dt`
    """
def euler_step(f: Any, y: Any, t: Any, dt: Any, params: Any) -> object {
    dy = f(y, t, *params) * dt;
    return dy;
}