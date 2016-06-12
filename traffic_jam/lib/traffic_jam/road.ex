defmodule TrafficJam.Road do
  # Client API

  def start_link(road_width, car_width, cars)
  when is_integer(road_width) and road_width > 0
  and is_integer(cars) and cars > 0 and cars <= road_width do
    Agent.start_link(
      fn -> init(road_width, car_width, cars) end,
      name:  __MODULE__
    )
  end

  def place_car(position) when is_integer(position) and position >= 0 do
    Agent.update(__MODULE__, fn set -> handle_place_car(set, position) end)
  end

  def move_car(position, new_position)
  when is_integer(position) and position >= 0
  and is_integer(new_position) and new_position >= 0 do
    Agent.update(__MODULE__, fn set ->
      handle_move_car(set, position, new_position)
    end)
  end

  def get_cars do
    Agent.get(__MODULE__, &handle_get_cars/1)
  end

  # Server API

  defp init(road_width, car_width, cars) do
    init_cars(road_width, car_width, cars)
    MapSet.new
  end

  defp handle_place_car(cars, position), do: MapSet.put(cars, position)

  defp handle_move_car(cars, position, new_position) do
    MapSet.delete(cars, position) |> MapSet.put(new_position)
  end

  defp handle_get_cars(cars), do: cars

  # Helpers

  defp init_cars(road_width, car_width, cars) do
    positions = div(road_width, car_width)
    0..(positions - 1)
    |> Enum.shuffle
    |> Enum.take(cars)
    |> Enum.map(fn position -> position * car_width end)
    |> Enum.sort(fn a, b -> b < a end)
    |> start_cars(car_width, road_width, nil, nil)
  end

  defp start_cars([position | positions], car_width, road_width, first, last) do
    {:ok, car} =
      Supervisor.start_child(
        TrafficJam.CarSupervisor,
        [position, car_width, road_width, last]
      )
    start_cars(positions, car_width, road_width, first || car, car)
  end
  defp start_cars([ ], _car_width, _road_width, first, last) do
    TrafficJam.Car.assign_leader(first, last)
  end
end
