defmodule SlimeMold do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    width = Application.fetch_env!(:slime_mold, :board_width)
    height = Application.fetch_env!(:slime_mold, :board_height)

    children = [
      # Define workers and child supervisors to be supervised
      supervisor(Task.Supervisor, [[name: SlimeMold.Actives]]),
      worker(SlimeMold.Board, [{width, height}]),
      worker(SlimeMold.Renderer, [ ])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: SlimeMold.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
