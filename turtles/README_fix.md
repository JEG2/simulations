# Turtle Ecology Fix Simulation

This is the same simulation as before.  It is complete and runs.

The current code has a design flaw though.  The `Turtles.Clock` is coupled to `Turtles.Painter`.  The goal of this exercise is to break that coupling.

Fixing the design will expose drawing bugs.  Fixing those bugs requires simplifying how changes are managed in `Turtles.World`.

## Instructions

1. Run `mix deps.get`
2. Remove `Clock.advance(Clock)` in `Turtles.Painter`
3. Make `Turtles.Clock` handle its own ticking by replacing `start_link/4` with:

    ```elixir
    def start_link(world, size, turtle_starter, options \\ [ ]) do
      clock = %__MODULE__{world: world, size: size, turtle_starter: turtle_starter}
      with {:ok, pid} = GenServer.start_link(__MODULE__, clock, options),
           :timer.send_interval(300, pid, :tick),
        do: {:ok, pid}
    end
   ```

4. Switch `Turtles.Clock`'s `handle_call(:tick, _from, clock = …)` to
   `handle_info(:tick, clock = …)`
5. Set `:paint_interval` to `100` in `lib/turtles.ex`
6. Run `iex -S mix` to view the drawing bugs
7. Replace `Turtles.World`'s empty changes with an empty list:  `[ ]`
8. Fix the server callbacks in `Turtles.World` to build up changes of the form
   `{:clear | :plant | :turtle, {x, y}}`
9. Adjust `Turtles.Painter.paint/4` to draw the new change format
10. Run `iex -S mix` to view the final simulation
