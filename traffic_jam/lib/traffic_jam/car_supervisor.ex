defmodule TrafficJam.CarSupervisor do
  def start_link do
    import Supervisor.Spec

    children = [
      worker(TrafficJam.Car, [ ], restart: :transient)
    ]

    Supervisor.start_link(
      children,
      strategy: :simple_one_for_one,
      name: __MODULE__
    )
  end
end
