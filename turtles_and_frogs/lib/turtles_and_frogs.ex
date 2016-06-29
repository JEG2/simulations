defmodule TurtlesAndFrogs do
  use Application

  @width 64
  @height 128
  @scale 5

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    canvas_options = [
      width: @width * @scale,
      height: @height * @scale,
      paint_interval: 100,
      painter_module: TurtlesAndFrogs.Painter,
      painter_state: @scale,
      brushes: %{
        blue: {0, 0, 50, 255},
        red: {150, 0, 0, 255},
        green: {0, 150, 0, 255}
      }
    ]

    children = [
      # Define workers and child supervisors to be supervised
      supervisor(Task.Supervisor, [[name: TurtlesAndFrogs.Critters]]),
      worker(TurtlesAndFrogs.Pond, [{@width, @height}, 3_000, 3_000]),
      worker(Canvas.GUI, [canvas_options])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_all, name: TurtlesAndFrogs.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
