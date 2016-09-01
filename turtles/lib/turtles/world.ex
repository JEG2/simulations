defmodule Turtles.World do
  defmodule Changes do
    defstruct clears: [ ], plants: [ ], turtles: [ ]

    def empty do
      %__MODULE__{ }
    end
  end

  defstruct size: nil,
            plants: MapSet.new,
            turtles: MapSet.new,
            changes: Changes.empty

  # Client API

  def start_link(size, options \\ [ ]) do
    Agent.start_link(fn -> init(size) end, options)
  end

  def changes(world) do
    Agent.get_and_update(world, &handle_changes/1)
  end

  #
  # locations is a list of x, y tuples:
  #
  #     [{0, 0}, {0, 1}, …]
  #
  def place_plants(world, locations) do
    Agent.update(world, fn struct -> handle_place_plants(struct, locations) end)
  end

  #
  # locations is a list of x, y tuples:
  #
  #     [{0, 0}, {0, 1}, …]
  #
  def place_turtles(world, locations) do
    Agent.update(world, fn struct -> handle_place_turtles(struct, locations) end)
  end

  def eat_or_move(world, location, move_location) do
    Agent.get_and_update(world, fn struct ->
      handle_eat_or_move(struct, location, move_location)
    end)
  end

  def eat_or_die(world, location) do
    Agent.get_and_update(world, fn struct ->
      handle_eat_or_die(struct, location)
    end)
  end

  def give_birth(world, new_location) do
    Agent.get_and_update(world, fn struct ->
      handle_give_birth(struct, new_location)
    end)
  end

  # Server API

  defp init(size = {width, height}) do
    background = for x <- 0..(width - 1), y <- 0..(height - 1) do {x, y} end
    %__MODULE__{size: size, changes: %Changes{clears: background}}
  end

  defp handle_changes(world = %__MODULE__{changes: changes}) do
    {changes, %__MODULE__{world | changes: Changes.empty}}
  end

  defp handle_place_plants(
    world = %__MODULE__{plants: plants, changes: changes},
    locations
  ) do
    {new_plants, new_plant_changes} =
      add_with_changes(plants, changes.plants, Enum.uniq(locations))
    new_changes = %Changes{changes | plants: new_plant_changes}
    %__MODULE__{world | plants: new_plants, changes: new_changes}
  end

  defp handle_place_turtles(
    world = %__MODULE__{turtles: turtles, changes: changes},
    locations
  ) do
    {new_turtles, new_turtle_changes} =
      add_with_changes(turtles, changes.turtles, Enum.uniq(locations))
    new_changes = %Changes{changes | turtles: new_turtle_changes}
    %__MODULE__{world | turtles: new_turtles, changes: new_changes}
  end

  defp handle_eat_or_move(
    world = %__MODULE__{plants: plants, turtles: turtles, changes: changes},
    location,
    move_location
  ) do
    cond do
      MapSet.member?(plants, location) ->
        eat(world, location)
      not MapSet.member?(turtles, move_location) ->
        new_turtles =
          MapSet.delete(turtles, location)
          |> MapSet.put(move_location)
        new_changes = %Changes{
          changes |
          clears: [location | changes.clears],
          turtles: [move_location | changes.turtles]
        }
        {:moved, %__MODULE__{world | turtles: new_turtles, changes: new_changes}}
      true ->
        {:pass, world}
    end
  end

  defp handle_eat_or_die(
    world = %__MODULE__{plants: plants, turtles: turtles, changes: changes},
    location
  ) do
    cond do
      MapSet.member?(plants, location) ->
        eat(world, location)
      true ->
        new_turtles = MapSet.delete(turtles, location)
        new_changes = %Changes{changes | clears: [location | changes.clears]}
        {:died, %__MODULE__{world | turtles: new_turtles, changes: new_changes}}
    end
  end

  defp handle_give_birth(
    world = %__MODULE__{turtles: turtles, changes: changes},
    new_location
  ) do
    if not MapSet.member?(turtles, new_location) do
      new_turtles = MapSet.put(turtles, new_location)
      new_changes = %Changes{changes | turtles: [new_location | changes.turtles]}
      {:birthed, %__MODULE__{world | turtles: new_turtles, changes: new_changes}}
    else
      {:pass, world}
    end
  end

  # Helpers

  defp add_with_changes(set, changes, [ ]), do: {set, changes}
  defp add_with_changes(set, changes, [location | locations]) do
    new_set = MapSet.put(set, location)
    new_changes = [location | changes]
    add_with_changes(new_set, new_changes, locations)
  end

  defp eat(world = %__MODULE__{plants: plants, changes: changes}, location) do
    new_plants = MapSet.delete(plants, location)
    new_changes = %Changes{
      changes |
      clears: [location | changes.clears],
      turtles: [location | changes.turtles]
    }
    {:ate, %__MODULE__{world | plants: new_plants, changes: new_changes}}
  end
end
