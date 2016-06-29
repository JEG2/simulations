defmodule TurtlesAndFrogs.Pond do
  defstruct turtles: %{ }, frogs: %{ }, changes: [ ]

  # Client API

  def start_link(size, turtle_count, frog_count) do
    Agent.start_link(
      fn -> init(size, turtle_count, frog_count) end,
      name: __MODULE__
    )
  end

  def look_around(neighbors, type) do
    Agent.get(
      __MODULE__,
      fn struct -> handle_look_around(struct, neighbors, type) end
    )
  end

  def try_move(old_xy, new_xy, type) do
    Agent.get_and_update(
      __MODULE__,
      fn struct -> handle_try_move(struct, old_xy, new_xy, type) end
    )
  end

  def get_changes do
    Agent.get_and_update(__MODULE__, fn struct -> handle_get_changes(struct) end)
  end

  # Server API

  defp init(size = {width, height}, turtle_count, frog_count) do
    xys =
      for x <- 0..(width - 1), y <- 0..(height - 1) do {x, y} end
      |> Enum.shuffle
      |> Enum.take(turtle_count + frog_count)
    turtles =
      xys
      |> Enum.take(turtle_count)
      |> build_critter_list(:turtle, size)
    frogs =
      xys
      |> Enum.drop(turtle_count)
      |> build_critter_list(:frog, size)
    grid =
      for y <- 0..(height - 1) do
        for x <- 0..(width - 1) do
          cond do
            Map.has_key?(frogs, {x, y}) -> 2
            Map.has_key?(turtles, {x, y}) -> 1
            true -> 0
          end
        end
      end
    %__MODULE__{turtles: turtles, frogs: frogs, changes: [{:init, grid}]}
  end

  defp handle_look_around(pond, neighbors, type) do
    Enum.map(neighbors, fn xy ->
      [Map.get(same_kind(pond, type), xy, 0), 1] |> Enum.min
    end)
  end

  defp handle_try_move(
    pond = %__MODULE__{changes: changes},
    old_xy,
    new_xy,
    type
  ) do
    if count_critters_at(new_xy, pond) == 0 do
      critters = same_kind(pond, type)
      removed =
        if Map.fetch!(critters, old_xy) == 1 do
          Map.delete(critters, old_xy)
        else
          Map.update!(critters, old_xy, fn count -> count - 1 end)
        end
      added = Map.update(removed, new_xy, 1, fn count -> count + 1 end)
      left = [{:remove, old_xy} | changes]
      new_pond =
        if type == :turtle do
          %__MODULE__{
            pond |
            turtles: added,
            changes: [{:add_turtle, new_xy} | left]
          }
        else
          %__MODULE__{
            pond |
            frogs: added,
            changes: [{:add_frog, new_xy} | left]
          }
        end
      {new_xy, new_pond}
    else
      {old_xy, pond}
    end
  end

  defp handle_get_changes(pond = %__MODULE__{changes: changes}) do
    {Enum.reverse(changes), %__MODULE__{pond | changes: [ ]}}
  end

  # Helpers

  defp build_critter_list(xys, type, size) do
    Enum.reduce(xys, %{ }, fn xy, counts ->
      Task.Supervisor.start_child(
        TurtlesAndFrogs.Critters,
        TurtlesAndFrogs.Critter,
        :start,
        [xy, type, size]
      )
      Map.update(counts, xy, 1, fn count -> count + 1 end)
    end)
  end

  defp same_kind(%__MODULE__{turtles: turtles}, :turtle), do: turtles
  defp same_kind(%__MODULE__{frogs: frogs}, :frog), do: frogs

  defp count_critters_at(xy, %__MODULE__{turtles: turtles, frogs: frogs}) do
    Map.get(turtles, xy, 0) + Map.get(frogs, xy, 0)
  end
end
