# Turtle Ecology Simulation

The goal of this exercise is to build a simulation of turtles that walk around, eat food, reproduce, and die.

The simulation is built, minus a `Turtles.Clock` process that you need to add.

The `Turtles.Clock` is responsible for managing time in the simulation.  When the clock is started, it places plants and turtles in the `Turtles.World`.  After that, as time advances, the clock tells each live turtle to act.  New turtles may be born as a result of these actions.  When they are, the clock must make them act in future actions.  Finally, the clock should note when a turtle dies, so they are no longer told to act.

## Instructions

1. Run `mix test --exclude todo`
2. Fix the failing test
3. Remove the highest `@tag todo: true` line found in `test/clock_test.exs`
4. If a line was removed in step 3, go back to step 1
5. Run `iex -S mix` to view the final simulation
