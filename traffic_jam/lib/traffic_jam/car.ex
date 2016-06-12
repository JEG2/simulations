defmodule TrafficJam.Car do
  defstruct ~w[position car_width road_width speed leader]a

  @max_speed 3.0

  use GenServer
  require Logger

  # Client API

  def start_link(position, car_width, road_width, leader) do
    GenServer.start_link(__MODULE__, [position, car_width, road_width, leader])
  end

  def assign_leader(car, leader) do
    GenServer.cast(car, {:assign_leader, leader})
  end

  def get_lead(pid, position) do
    GenServer.call(pid, {:get_lead, position})
  end

  # Server API

  def init([position, car_width, road_width, leader]) do
    GenServer.cast(self, :finish_init)
    initial_state = %__MODULE__{
      position: position,
      car_width: car_width,
      road_width: road_width,
      speed: :rand.uniform * @max_speed,
      leader: leader
    }
    {:ok, initial_state}
  end

  def handle_call(
    {:get_lead, follower_position},
    _from,
    state = %__MODULE__{position: position, road_width: road_width}
  ) do
    adjusted_position =
      if position < follower_position, do: position + road_width, else: position
    {:reply, adjusted_position - follower_position, state}
  end
  def handle_call(message, _from, state) do
    Logger.debug "Unhandled call:  #{inspect message}"
    {:reply, :ok, state}
  end

  def handle_cast(:finish_init, state = %__MODULE__{position: position}) do
    TrafficJam.Road.place_car(position)
    :timer.send_interval(333, :move)
    {:noreply, state}
  end
  def handle_cast({:assign_leader, leader}, state) do
    {:noreply, %__MODULE__{state | leader: leader}}
  end
  def handle_cast(message, state) do
    Logger.debug "Unhandled cast:  #{inspect message}"
    {:noreply, state}
  end

  def handle_info(
    :move,
    state = %__MODULE__{
      position: position,
      car_width: car_width,
      road_width: road_width,
      speed: speed,
      leader: leader
    }
  ) do
    new_speed = adjust_speed(position, car_width, speed, leader)
    new_position = move(position, road_width, new_speed)
    update_position(position, new_position)
    {:noreply, %__MODULE__{state | position: new_position}}
  end
  def handle_info(message, state) do
    Logger.debug "Unhandled info:  #{inspect message}"
    {:noreply, state}
  end

  # Helpers

  defp adjust_speed(position, car_width, speed, leader) do
    bumped = speed + 0.5
    current_max =
      case TrafficJam.Car.get_lead(leader, position) do
        distance when distance < car_width + 1 + @max_speed ->
          Enum.max([0, distance - (car_width + 1)])
        _distance ->
          @max_speed
      end
    if bumped > current_max, do: current_max, else: bumped
  end

  defp move(position, road_width, speed) do
    case position + speed do
      new_position when new_position >= road_width -> new_position
      new_position -> new_position
    end
  end

  defp update_position(old_position, new_position) do
    trunced_old_position = trunc(old_position)
    trunced_new_position = trunc(new_position)
    if trunced_old_position != trunced_new_position do
      TrafficJam.Road.move_car(trunced_old_position, trunced_new_position)
    end
  end
end
