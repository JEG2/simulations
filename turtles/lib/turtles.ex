defmodule Turtles do
  use Application

  @width 128
  @height 128
  @scale 4

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    canvas_options = [
      width: @width * @scale,
      height: @height * @scale,
      paint_interval: 500,
      painter_module: Turtles.Painter,
      painter_state: @scale,
      brushes: %{
        black: {0, 0, 0, 255},
        red: {150, 0, 0, 255},
        green: {0, 150, 0, 255}
      }
    ]
    turtle_starter = fn args ->
      apply(Turtles.Turtle, :start_supervised, args)
    end

    # Define workers and child supervisors to be supervised
    children =
      if Mix.env != :test do
        [
          # Starts a worker by calling: Turtles.Worker.start_link(arg1, arg2, arg3)
          supervisor(
            Supervisor,
            [ [worker(Turtles.Turtle, [ ], restart: :transient)],
              [name: Turtles.TurtleSupervisor, strategy: :simple_one_for_one] ]
          ),
          worker(Turtles.World, [{@width, @height}, [name: Turtles.World]]),
          worker(
            Turtles.Clock,
            [ Turtles.World,
              {@width, @height},
              turtle_starter,
              [name: Turtles.Clock] ]
          ),
          worker(Canvas.GUI, [canvas_options])
        ]
      else
        [ ]
      end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_all, name: Turtles.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
