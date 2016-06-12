defmodule TrafficJam do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    road_width = Application.fetch_env!(:traffic_jam, :road_width)
    road_height = Application.fetch_env!(:traffic_jam, :road_height)
    car_width = Application.fetch_env!(:traffic_jam, :car_width)
    paint_delay = Application.fetch_env!(:traffic_jam, :paint_delay)
    cars = Application.fetch_env!(:traffic_jam, :cars)

    children = [
      # Define workers and child supervisors to be supervised
      supervisor(TrafficJam.CarSupervisor, [ ]),
      worker(TrafficJam.Road, [road_width, car_width, cars]),
      worker(
        TrafficJam.Window,
        [paint_delay, {road_width, road_height}, car_width]
      )
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_all, name: TrafficJam.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
