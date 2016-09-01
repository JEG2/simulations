defmodule ForestFireSim.Fire do
  def ignite(world, xy, intensity) do
    spawn_link(__MODULE__, :burn, [world, xy, intensity])
  end

  def burn(_world, _xy, 0), do: :ok
  def burn(world, xy, intensity) do
    receive do
      :advance ->
        advance(world, xy)
        burn(world, xy, intensity - 1)
    end
  end

  defp advance(world, xy) do
    send(world, {:advance_fire, xy})
  end
end
