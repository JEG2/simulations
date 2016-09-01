defmodule Turtles.Turtle do
  use GenServer

  alias Turtles.{World, TurtleSupervisor}

  @headings ~w[north northeast east southeast south southwest west northwest]a
  @starting_energy 10

  defstruct world: nil,
            size: nil,
            turtle_starter: nil,
            location: nil,
            heading: nil,
            energy: @starting_energy

  # Client API

  def start_link(world, size, turtle_starter, location, heading, energy) do
    turtle = %__MODULE__{
      world: world,
      size: size,
      turtle_starter: turtle_starter,
      location: location,
      heading: heading,
      energy: energy
    }
    GenServer.start_link(__MODULE__, turtle)
  end

  def start_supervised(
    world, size, turtle_starter, location, energy \\ @starting_energy
  ) do
    Supervisor.start_child(
      TurtleSupervisor,
      [world, size, turtle_starter, location, random_heading, energy]
    )
  end

  def get_location(pid) do
    GenServer.call(pid, :get_location)
  end

  def get_heading(pid) do
    GenServer.call(pid, :get_heading)
  end

  def get_energy(pid) do
    GenServer.call(pid, :get_energy)
  end

  # returns :ok or the pid of a newborn turtle
  def act(pid) do
    GenServer.call(pid, :act)
  end

  # Server API

  def handle_call(
    :get_location,
    _from,
    turtle = %__MODULE__{location: location}
  ) do
    {:reply, location, turtle}
  end

  def handle_call(:get_heading, _from, turtle = %__MODULE__{heading: heading}) do
    {:reply, heading, turtle}
  end

  def handle_call(:get_energy, _from, turtle = %__MODULE__{energy: energy}) do
    {:reply, energy, turtle}
  end

  def handle_call(:act, _from, turtle) do
    {new_turtle, pid} = do_act(turtle) |> record_action
    if new_turtle.energy > 0 do
      {:reply, pid || :ok, new_turtle}
    else
      {:stop, :normal, pid || :ok, new_turtle}
    end
  end

  # Helpers

  defp random_heading, do: Enum.at(@headings, :rand.uniform(8) - 1)

  defp do_act(turtle = %__MODULE__{world: world, energy: energy})
  when energy >= 15 do
    {birth_location, moved_turtle} = pick_moved_location(turtle)
    {turtle, moved_turtle, World.give_birth(world, birth_location)}
  end
  defp do_act(
    turtle = %__MODULE__{world: world, location: location, energy: energy}
  )
  when energy < 1 do
    {turtle, turtle, World.eat_or_die(world, location)}
  end
  defp do_act(
    turtle = %__MODULE__{world: world, location: location}
  ) do
    {moved_location, moved_turtle} = pick_moved_location(turtle)
    {turtle, moved_turtle, World.eat_or_move(world, location, moved_location)}
  end

  defp pick_moved_location(
    turtle = %__MODULE__{size: size, location: location, heading: heading}
  ) do
    index =
      @headings
      |> Enum.with_index
      |> Enum.find(fn {h, _i} -> h == heading end)
      |> elem(1)
    new_heading = Enum.at(@headings, drift(index))
    new_location = move(size, location, new_heading)
    new_turtle =
      %__MODULE__{turtle | location: new_location, heading: new_heading}
    {new_location, new_turtle}
  end

  defp drift(i) do
    rem(i + (:rand.uniform(3) - 2), 8)
  end

  defp move(size, {x, y}, :north),     do: wrap(size, {x,     y - 1})
  defp move(size, {x, y}, :northeast), do: wrap(size, {x + 1, y - 1})
  defp move(size, {x, y}, :east),      do: wrap(size, {x + 1, y})
  defp move(size, {x, y}, :southeast), do: wrap(size, {x + 1, y + 1})
  defp move(size, {x, y}, :south),     do: wrap(size, {x,     y + 1})
  defp move(size, {x, y}, :southwest), do: wrap(size, {x - 1, y + 1})
  defp move(size, {x, y}, :west),      do: wrap(size, {x - 1, y})
  defp move(size, {x, y}, :northwest), do: wrap(size, {x - 1, y - 1})

  defp wrap(size, location), do: wrap_width(size, location)

  defp wrap_width(size = {width, _height}, {-1, y}) do
    wrap_height(size, {width - 1, y})
  end
  defp wrap_width(size = {width, _height}, {x, y}) do
    wrap_height(size, {rem(x, width), y})
  end

  defp wrap_height({_width, height}, {x, -1}) do
    {x, height - 1}
  end
  defp wrap_height({_width, height}, {x, y}) do
    {x, rem(y, height)}
  end

  defp record_action(
    {turtle = %__MODULE__{energy: energy}, _moved_turtle, :ate}
  ) do
    {%__MODULE__{turtle | energy: energy + 1}, nil}
  end
  defp record_action({turtle, _moved_turtle, :died}) do
    {%__MODULE__{turtle | energy: 0}, nil}
  end
  defp record_action(
    {_turtle, moved_turtle = %__MODULE__{energy: energy}, :moved}
  ) do
    {%__MODULE__{moved_turtle | energy: energy - 0.1}, nil}
  end
  defp record_action(
    { turtle = %__MODULE__{
        world: world,
        size: size,
        energy: energy,
        turtle_starter: turtle_starter
      },
      %__MODULE__{location: birth_location},
      :birthed }
  ) do
    split_energy = energy / 2
    {:ok, pid} = turtle_starter.(
      [world, size, turtle_starter, birth_location, split_energy]
    )
    {%__MODULE__{turtle | energy: split_energy}, pid}
  end
  defp record_action({turtle, _moved_turtle, :pass}), do: {turtle, nil}
end
