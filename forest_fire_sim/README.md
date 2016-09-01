# Forest Fire Simulation

The goal of this exercise is to build a simulation of a forest fire spreading through some trees.

A `ForestFireSim.Forest` data structure is already provided, but modules for the individual processes involved in the simulation had been left out.  You can look through the documentation of `ForestFireSim.Forest` to learn which operations are provided.  (You won't need to add anymore.)

A `ForestFireSim.Fire` process will be spawned as each fire ignites.  It should use the arrival of `:advance` messages to notify the `world` of the change, until its `intensity` runs out.

There also will be one `ForestFireSim.World` process that will track the current state of the `forest` and `:render` it to the screen on demand.

You can use the tests to recreate these processes.  Start with `ForestFireSim.Fire`.  It has no dependencies.  You can move to `ForestFireSim.World` next, which makes use of the `ForestFireSim.Forest` data structure.

## Instructions

1. Run `mix test --exclude todo`
2. Fix the failing test
3. Remove the highest `@tag todo: true` line found in `test/fire_test.exs` or
   `test/world_test.exs`
4. If a line was removed in step 3, go back to step 1
5. Run `mix` to view the final simulation
