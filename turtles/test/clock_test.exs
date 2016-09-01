defmodule ClockTest do
  use ExUnit.Case, async: true

  ###############################
  ### Tests start on line 57! ###
  ###############################

  alias Turtles.{Clock, World}

  defmodule FakeTurtle do
    use GenServer

    def start_link(_world, _size, _turtle_starter, _location, _energy \\ 10) do
      GenServer.start_link(__MODULE__, nil)
    end

    def init(nil) do
      turtle = self
      Agent.update(FakeTurtles, fn turtles ->
        Map.update!(turtles, :turtles, fn pids -> [turtle | pids] end)
      end)
      {:ok, nil}
    end

    def handle_call(:act, _from, nil) do
      Agent.update(FakeTurtles, fn turtles ->
        Map.update!(turtles, :act_count, fn count -> count + 1 end)
      end)
      newborns = Agent.get_and_update(FakeTurtles, fn
        turtles = %{births: 0} -> {0, turtles}
        turtles = %{births: births} -> {births, %{turtles | births: births - 1}}
      end)
      reply = if newborns > 0 do
        {:ok, pid} =
          __MODULE__.start_link(:world, :size, :turtle_starter, :location)
        pid
      else
        :ok
      end
      {:reply, reply, nil}
    end
  end

  @size {100, 100}

  setup do
    {:ok, world} = World.start_link(@size)

    Agent.start_link(fn ->
      %{turtles: [ ], act_count: 0, births: 0}
    end, name: FakeTurtles)
    fake_turtle_starter = fn args -> apply(FakeTurtle, :start_link, args) end

    [world: world, fake_turtle_starter: fake_turtle_starter]
  end

  test "plants are populated (20% of the world) at the dawn of time",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    {:ok, _clock} = Clock.start_link(world, @size, fake_turtle_starter)
    expected_count = round(elem(@size, 0) * elem(@size, 1) * 0.2)
    assert length(World.changes(world).plants) == expected_count
  end

  @tag todo: true
  test "300 turtles are born at the dawn of time",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    {:ok, _clock} = Clock.start_link(world, @size, fake_turtle_starter)
    assert length(World.changes(world).turtles) == 300
  end

  @tag todo: true
  test "starts a process for each turtle as it is born",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    {:ok, _clock} = Clock.start_link(world, @size, fake_turtle_starter)
    count = Agent.get(FakeTurtles, fn turtles ->
      length(Map.get(turtles, :turtles))
    end)
    assert count == 300
  end

  @tag todo: true
  test "instructs each turtle to act as time advances",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    {:ok, clock} = Clock.start_link(world, @size, fake_turtle_starter)
    Clock.advance(clock)
    count = Agent.get(FakeTurtles, fn turtles ->
      Map.get(turtles, :act_count)
    end)
    assert count == 300
  end

  @tag todo: true
  test "tracks new turtles born during the actions of others",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    {:ok, clock} = Clock.start_link(world, @size, fake_turtle_starter)

    Agent.update(FakeTurtles, fn turtles -> Map.put(turtles, :births, 1) end)
    Clock.advance(clock)
    count = Agent.get(FakeTurtles, fn turtles ->
      length(Map.get(turtles, :turtles))
    end)
    assert count == 301

    Clock.advance(clock)
    count = Agent.get(FakeTurtles, fn turtles ->
      Map.get(turtles, :act_count)
    end)
    assert count == 601
  end

  @tag todo: true
  test "stops tracking turtles when they die",
       %{world: world, fake_turtle_starter: fake_turtle_starter} do
    {:ok, clock} = Clock.start_link(world, @size, fake_turtle_starter)
    turtle = Agent.get_and_update(FakeTurtles, fn
      turtles = %{turtles: [death | rest]} -> {death, %{turtles | turtles: rest}}
    end)
    GenServer.stop(turtle)
    Clock.advance(clock)
    count = Agent.get(FakeTurtles, fn turtles ->
      Map.get(turtles, :act_count)
    end)
    assert count == 299
  end
end
