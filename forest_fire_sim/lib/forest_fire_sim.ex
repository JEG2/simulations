defmodule ForestFireSim do
  alias ForestFireSim.{Fire, Forest, World}

  def start do
    forest = Forest.generate(%{width: 80, height: 24, percent: 66})
    fire_starter = fn {xy, intensity} ->
      fire = Fire.ignite(self, xy, intensity)
      :timer.send_interval(1_000, fire, :advance)
    end
    world = World.create(forest, fire_starter)
    :timer.send_interval(1_000, world, :render)
  end
end
