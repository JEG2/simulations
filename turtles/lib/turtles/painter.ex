defmodule Turtles.Painter do
  alias Canvas.GUI.Brush
  alias Turtles.{World, Clock}

  def paint(canvas, _width, _height, scale) do
    %{clears: clears, plants: plants, turtles: turtles} =
      World.changes(World)

    Enum.each(clears, fn location -> clear(canvas, scale, location) end)
    Enum.each(plants, fn location -> paint_plant(canvas, scale, location) end)
    Enum.each(turtles, fn location -> paint_turtle(canvas, scale, location) end)

    Clock.advance(Clock)
  end

  defp clear(canvas, scale, {x, y}) do
    Brush.draw_rectangle(canvas, {x * scale, y * scale}, {scale, scale}, :black)
  end

  defp paint_plant(canvas, scale, {x, y}) do
    plant_size = round(scale / 2)
    offset = round((scale - plant_size) / 2)
    Brush.draw_rectangle(
      canvas,
      {x * scale + offset, y * scale + offset},
      {plant_size, plant_size},
      :green
    )
  end

  defp paint_turtle(canvas, scale, {x, y}) do
    turtle_size = round(scale / 2)
    turtle_radius = round(turtle_size / 2)
    offset = round((scale - turtle_size) / 2)
    Brush.draw_circle(
      canvas,
      {x * scale + offset + turtle_radius, y * scale + offset + turtle_radius},
      turtle_radius,
      :red
    )
  end

  def handle_key_down(
    %{key: ?Q, shift: false, alt: false, control: false, meta: false},
    _scale
  ) do
    System.halt(0)
  end
  def handle_key_down(_key_combo, scale), do: scale
end
