defmodule Turtles.Clock do
  use GenServer

  require Logger

  alias Turtles.{World, Turtle}

  defstruct world: nil, size: nil, turtle_starter: nil, turtles: MapSet.new

  # Client API

  def start_link(world, size, turtle_starter, options \\ [ ]) do
    clock = %__MODULE__{world: world, size: size, turtle_starter: turtle_starter}
    GenServer.start_link(__MODULE__, clock, options)
  end

  def advance(clock) do
    GenServer.call(clock, :tick)
  end

  # Server API

  def init(
    clock = %__MODULE__{
      world: world,
      size: size = {width, height},
      turtle_starter: turtle_starter
    }
  ) do
    plants = place(round(width * height * 0.2), size, MapSet.new)
    World.place_plants(world, plants)

    turtles = place(300, size, MapSet.new)
    World.place_turtles(world, turtles)
    turtle_pids =
      Enum.reduce(turtles, MapSet.new, fn location, set ->
        {:ok, pid} = turtle_starter.([world, size, turtle_starter, location])
        Process.monitor(pid)
        MapSet.put(set, pid)
      end)

    new_clock =
      %__MODULE__{clock | turtles: turtle_pids}
    {:ok, new_clock}
  end

  def handle_call(
    :tick,
    _from,
    clock = %__MODULE__{
      world: world,
      size: size = {width, height},
      turtles: turtles
    }
  ) do
    plants = place(round(width * height / 1_000), size, MapSet.new)
    World.place_plants(world, plants)

    new_turtles =
      Enum.reduce(turtles, turtles, fn turtle, set ->
        case Turtle.act(turtle) do
          pid when is_pid(pid) ->
            # Logger.info "Turtles:  #{MapSet.size(set) + 1}"
            Process.monitor(pid)
            MapSet.put(set, pid)
          :ok ->
            set
        end
      end)

    {:reply, :ok, %__MODULE__{clock | turtles: new_turtles}}
  end

  def handle_info(
    {:DOWN, _reference, :process, pid, _reason},
    clock = %__MODULE__{turtles: turtles}
  ) do
    # Logger.info "Turtles:  #{MapSet.size(turtles) - 1}"
    {:noreply, %__MODULE__{clock | turtles: MapSet.delete(turtles, pid)}}
  end
  def handle_info(message, clock) do
    Logger.debug "Unexpected message:  #{message}"
    {:noreply, clock}
  end

  # Helpers

  defp place(0, _size, locations), do: Enum.to_list(locations)
  defp place(count, size = {width, height}, locations) do
    location = {:rand.uniform(width) - 1, :rand.uniform(height) - 1}
    new_count = count - (if MapSet.member?(locations, location), do: 0, else: 1)
    place(new_count, size, MapSet.put(locations, location))
  end
end
