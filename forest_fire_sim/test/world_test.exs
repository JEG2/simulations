defmodule WorldTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias ForestFireSim.{Forest, World}

  @tag todo: true
  test "starts fires for all initial fires" do
    forest = Forest.from_string("&*")
    test_process = self
    fire_starter = fn {xy, intensity} ->
      send(test_process, {:fire_started, xy, intensity})
    end
    World.create(forest, fire_starter)

    xy = {0, 0}
    intensity = 4
    assert_receive {:fire_started, ^xy, ^intensity}
  end

  @tag todo: true
  test "allows another process to peek at locations" do
    forest = Forest.from_string("&*")
    fire_starter = fn _fire -> :ok end
    world = World.create(forest, fire_starter)

    xy = {0, 0}
    reply_to = self
    send(world, {:debug_location, xy, reply_to})
    intensity = 4
    assert_receive {:debug_location_response, {:fire, ^intensity}}

    other_xy = {1, 0}
    send(world, {:debug_location, other_xy, reply_to})
    assert_receive {:debug_location_response, :tree}
  end

  @tag todo: true
  test "can advance a fire" do
    forest = Forest.from_string("&*")
    fire_starter = fn _fire -> :ok end
    world = World.create(forest, fire_starter)

    xy = {0, 0}
    send(world, {:advance_fire, xy})
    reply_to = self
    send(world, {:debug_location, xy, reply_to})
    intensity = 3
    assert_receive {:debug_location_response, {:fire, ^intensity}}
    neighbor_xy = {1, 0}
    send(world, {:debug_location, neighbor_xy, reply_to})
    fresh_fire_intensity = 4
    assert_receive {:debug_location_response, {:fire, ^fresh_fire_intensity}}
  end

  @tag todo: true
  test "starts new fires during an advance" do
    forest = Forest.from_string("&*")
    test_process = self
    fire_starter = fn {xy, intensity} ->
      send(test_process, {:fire_started, xy, intensity})
    end
    world = World.create(forest, fire_starter)
    xy = {0, 0}
    assert_receive {:fire_started, ^xy, 4}

    send(world, {:advance_fire, xy})
    neighbor_xy = {1, 0}
    intensity = 4
    assert_receive {:fire_started, ^neighbor_xy, ^intensity}
  end

  @tag todo: true
  test "can render the current state of the world" do
    forest = Forest.from_string("&*")
    fire_starter = fn _fire -> :ok end

    assert capture_io(fn ->
      world = World.create(forest, fire_starter)

      send(world, :render)
      # to ensure `world` is past the `:render` message
      xy = {0, 0}
      reply_to = self
      send(world, {:debug_location, xy, reply_to})
      assert_receive {:debug_location_response, _location}
    end) |> String.trim == Forest.to_string(forest)
  end
end
