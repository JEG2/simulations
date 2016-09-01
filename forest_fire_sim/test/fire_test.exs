defmodule FireTest do
  use ExUnit.Case, async: true

  alias ForestFireSim.Fire

  test "advance themselves in the `world` when they receive messages" do
    world = self
    xy = {4, 2}
    intensity = 2
    fire = Fire.ignite(world, xy, intensity)
    send(fire, :advance)
    assert_receive {:advance_fire, ^xy}
  end

  @tag todo: true
  test "burn for `intensity` number of `:advance` messages" do
    # ask to receive a message when `fire` exits:
    Process.flag(:trap_exit, true)

    world = self
    xy = {0, 0}
    intensity = 1
    fire = Fire.ignite(world, xy, intensity)
    send(fire, :advance)
    assert_receive {:advance_fire, ^xy}
    assert_receive {:EXIT, ^fire, :normal}  # `fire` exited

    intensity = 4
    bigger_fire = Fire.ignite(world, xy, intensity)
    Stream.repeatedly(fn ->
      send(bigger_fire, :advance)
      assert_receive {:advance_fire, ^xy}
    end)
    |> Enum.take(intensity)
    assert_receive {:EXIT, ^bigger_fire, :normal}  # `bigger_fire` exited
  end
end
