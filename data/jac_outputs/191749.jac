"""Returns the number of physics timesteps in a single control timestep.

  Args:
    control_timestep: Control time-step, should be an integer multiple of the
      physics timestep.
    physics_timestep: The time-step of the physics simulation.
    tolerance: Optional tolerance value for checking if `physics_timestep`
      divides `control_timestep`.

  Returns:
    The number of physics timesteps in a single control timestep.

  Raises:
    ValueError: If `control_timestep` is smaller than `physics_timestep` or if
      `control_timestep` is not an integer multiple of `physics_timestep`.
  """
def compute_n_steps(
    control_timestep: Any, physics_timestep: Any, tolerance: Any = 1e-08
) -> object {
    if (control_timestep < physics_timestep) {
        raise ValueError(
            'Control timestep ({}) cannot be smaller than physics timestep ({}).'.format(
                control_timestep, physics_timestep
            )
        );
    }
    if (
        abs(
            (
                (control_timestep / physics_timestep)
                - round((control_timestep / physics_timestep))
            )
        )
        > tolerance
    ) {
        raise ValueError(
            'Control timestep ({}) must be an integer multiple of physics timestep '
            '({})'.format(
                control_timestep, physics_timestep
            )
        );
    }
    return int(round((control_timestep / physics_timestep)));
}