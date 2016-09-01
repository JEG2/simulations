# Turtle Ecology Supervisors Simulation

This is the same simulation as before. All processes are complete this time, but the supervision tree has been removed.  The goal is to reconstruct the tree so the simulation runs again.

## Instructions

1. Run `mix deps.get`
2. Build a dynamic `Supervisor` that has one template to launch `Turtles.Turtle`
    * It needs to be named:  see `Turtles.Turtle.start_supervised/5`
    * `Turtles.Turtle` is a `:transient` process
3. A top-level `Supervisor` is also needed
    * It should supervise the `Supervisor` created in step 2
    * It should supervise `Turtles.World` which needs a matching name
    * It should supervise `Turtles.Clock` which needs a matching name
    * It should supervise a `Canvas.GUI` (`start_link/1` takes `canvas_options`)
    * If any of these processes fails, all should be relaunched
4. Run `iex -S mix` to view the final simulation
