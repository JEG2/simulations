defmodule WorldTest do
  use ExUnit.Case, async: true

  @size {100, 100}

  setup do
    {:ok, world} = Turtles.World.start_link(@size)
    [world: world]
  end

  test "begins with a full world clear", %{world: world} do
    all_locations =
      for x <- 0..(elem(@size, 0) - 1), y <- 0..(elem(@size, 1) - 1) do
        {x, y}
      end
    assert Turtles.World.changes(world).clears == all_locations
  end

  test "begins with no plant changes", %{world: world} do
    assert Turtles.World.changes(world).plants == [ ]
  end

  test "begins with no turtle changes", %{world: world} do
    assert Turtles.World.changes(world).turtles == [ ]
  end

  test "records plant placements", %{world: world} do
    Turtles.World.place_plants(world, [{0, 0}, {50, 50}])
    assert Turtles.World.changes(world).plants == [{50, 50}, {0, 0}]
  end

  test "records turtle placements", %{world: world} do
    Turtles.World.place_turtles(world, [{0, 0}, {50, 50}])
    assert Turtles.World.changes(world).turtles == [{50, 50}, {0, 0}]
  end

  test "turtles will eat if food is available", %{world: world} do
    Turtles.World.place_plants(world, [{0, 0}])
    Turtles.World.place_turtles(world, [{0, 0}])
    Turtles.World.changes(world)

    assert Turtles.World.eat_or_move(world, {0, 0}, {1, 0}) == :ate
    changes = Turtles.World.changes(world)
    assert changes.clears == [{0, 0}]
    assert changes.turtles == [{0, 0}]
  end

  test "turtles will move if no food is available and location is open",
       %{world: world} do
    Turtles.World.place_turtles(world, [{0, 0}])
    Turtles.World.changes(world)

    assert Turtles.World.eat_or_move(world, {0, 0}, {1, 0}) == :moved
    changes = Turtles.World.changes(world)
    assert changes.clears == [{0, 0}]
    assert changes.turtles == [{1, 0}]
  end

  test "turtles will pass if they can't eat or move", %{world: world} do
    Turtles.World.place_turtles(world, [{0, 0}, {1, 0}])
    Turtles.World.changes(world)

    assert Turtles.World.eat_or_move(world, {0, 0}, {1, 0}) == :pass
    assert Turtles.World.changes(world) == Turtles.World.Changes.empty
  end

  test "turtles will not die if food is available", %{world: world} do
    Turtles.World.place_plants(world, [{0, 0}])
    Turtles.World.place_turtles(world, [{0, 0}])
    Turtles.World.changes(world)

    assert Turtles.World.eat_or_die(world, {0, 0}) == :ate
    changes = Turtles.World.changes(world)
    assert changes.clears == [{0, 0}]
    assert changes.turtles == [{0, 0}]
  end

  test "turtles will die if no food is available", %{world: world} do
    Turtles.World.place_turtles(world, [{0, 0}])
    Turtles.World.changes(world)

    assert Turtles.World.eat_or_die(world, {0, 0}) == :died
    assert Turtles.World.changes(world).clears == [{0, 0}]
  end

  test "turtles can give birth on open locations", %{world: world} do
    Turtles.World.place_turtles(world, [{0, 0}])
    Turtles.World.changes(world)

    assert Turtles.World.give_birth(world, {1, 0}) == :birthed
    assert Turtles.World.changes(world).turtles == [{1, 0}]
  end

  test "turtles pass if they can't give birth", %{world: world} do
    Turtles.World.place_turtles(world, [{0, 0}, {1, 0}])
    Turtles.World.changes(world)

    assert Turtles.World.give_birth(world, {1, 0}) == :pass
    assert Turtles.World.changes(world) == Turtles.World.Changes.empty
  end

  test "clears changes as they are fetched", %{world: world} do
    assert Turtles.World.changes(world) != Turtles.World.Changes.empty
    assert Turtles.World.changes(world) == Turtles.World.Changes.empty
  end
end
