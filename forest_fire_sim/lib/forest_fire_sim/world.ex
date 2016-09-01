defmodule ForestFireSim.World do
  alias ForestFireSim.Forest

  def create(forest, fire_starter) do
    spawn_link(__MODULE__, :build, [forest, fire_starter])
  end

  def build(forest, fire_starter) do
    Forest.get_fires(forest)
    |> Enum.each(fire_starter)
    run(forest, fire_starter)
  end

  def run(forest, fire_starter) do
    receive do
      {:advance_fire, xy} ->
        {new_forest, new_fires} = Forest.spread_fire(forest, xy)
        Enum.each(new_fires, fire_starter)
        Forest.reduce_fire(new_forest, xy)
        |> run(fire_starter)
      {:debug_location, xy, from} ->
        location = Forest.get_location(forest, xy)
        send(from, {:debug_location_response, location})
        run(forest, fire_starter)
      :render ->
        Forest.to_string(forest)
        |> IO.puts
        run(forest, fire_starter)
    end
  end
end
