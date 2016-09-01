defmodule TurtleTest do
  use ExUnit.Case, async: true

  alias Turtles.{World, Turtle}

  @size {10, 10}

  setup do
    {:ok, world} = World.start_link(@size)
    fake_turtle_starter = fn _args -> {:ok, self} end
    [world: world, fake_turtle_starter: fake_turtle_starter]
  end

  test "turtles know their location",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    {:ok, turtle} =
      Turtle.start_link(world, @size, fake_turtle_starter, {1, 2}, :east, 1)
    assert Turtle.get_location(turtle) == {1, 2}
  end

  test "turtles know their heading",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    {:ok, turtle} =
      Turtle.start_link(world, @size, fake_turtle_starter, {0, 0}, :south, 1)
    assert Turtle.get_heading(turtle) == :south
  end

  test "turtles know their energy",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    {:ok, turtle} =
      Turtle.start_link(world, @size, fake_turtle_starter, {0, 0}, :east, 42)
    assert Turtle.get_energy(turtle) == 42
  end

  test "turtles will always try to eat first",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    World.place_plants(world, [{0, 0}])
    {:ok, turtle} =
      Turtle.start_link(world, @size, fake_turtle_starter, {0, 0}, :east, 1)
    Turtle.act(turtle)
    assert Turtle.get_energy(turtle) > 1
  end

  test "turtles with energy and no food will move",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    {:ok, turtle} =
      Turtle.start_link(world, @size, fake_turtle_starter, {0, 0}, :north, 1)
    Turtle.act(turtle)
    assert Turtle.get_location(turtle) in [{9, 9}, {0, 9}, {1, 9}]
    assert Turtle.get_heading(turtle) in ~w[northwest north northeast]a
    assert Turtle.get_energy(turtle) == 0.9
  end

  test "turtles will pass if they can't eat or move",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    World.place_turtles(world, [{1, 9}, {1, 0}, {1, 1}])
    {:ok, turtle} =
      Turtle.start_link(world, @size, fake_turtle_starter, {0, 0}, :east, 1)
    Turtle.act(turtle)
    assert Turtle.get_location(turtle) == {0, 0}
    assert Turtle.get_heading(turtle) == :east
    assert Turtle.get_energy(turtle) == 1
  end

  test "turtles without energy and no food will die",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    Process.flag(:trap_exit, true)
    {:ok, turtle} =
      Turtle.start_link(world, @size, fake_turtle_starter, {0, 0}, :east, 0.9)
    Turtle.act(turtle)
    assert_receive {:EXIT, ^turtle, :normal}
  end

  test "turtles with surplus energy will try to give birth",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    {:ok, turtle} =
      Turtle.start_link(world, @size, fake_turtle_starter, {0, 0}, :east, 15)
    Turtle.act(turtle)
    assert hd(World.changes(world).turtles) in [{1, 9}, {1, 0}, {1, 1}]
    assert Turtle.get_energy(turtle) == 7.5
  end
end
