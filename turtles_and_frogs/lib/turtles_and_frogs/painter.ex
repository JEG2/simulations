defmodule TurtlesAndFrogs.Painter do
  def paint(canvas, width, height, scale) do
    TurtlesAndFrogs.Pond.get_changes
    |> Enum.each(fn change ->
      paint_change(change, canvas, width, height, scale)
    end)
  end

  defp paint_change({:init, grid}, canvas, width, height, scale) do
    paint_pond(canvas, width, height)
    paint_grid(grid, canvas, scale)
  end
  defp paint_change({:remove, xy}, canvas, _width, _height, scale) do
    paint_critter(canvas, scale, xy, :blue)
  end
  defp paint_change({:add_turtle, xy}, canvas, _width, _height, scale) do
    paint_turtle(canvas, scale, xy)
  end
  defp paint_change({:add_frog, xy}, canvas, _width, _height, scale) do
    paint_frog(canvas, scale, xy)
  end

  defp paint_pond(canvas, width, height) do
    Canvas.GUI.Brush.draw_rectangle(canvas, {0, 0}, {width, height}, :blue)
  end

  defp paint_grid(grid, canvas, scale) do
    grid
    |> Enum.with_index
    |> Enum.each(fn {row, y} ->
      row
      |> Enum.with_index
      |> Enum.each(fn
        {0, _x} -> :ok
        {1, x} -> paint_turtle(canvas, scale, {x, y})
        {2, x} -> paint_frog(canvas, scale, {x, y})
      end)
    end)
  end

  defp paint_turtle(canvas, scale, xy) do
    paint_critter(canvas, scale, xy, :green)
  end

  defp paint_frog(canvas, scale, xy) do
    paint_critter(canvas, scale, xy, :red)
  end

  defp paint_critter(canvas, scale, {x, y}, color) do
    Canvas.GUI.Brush.draw_circle(
      canvas,
      {x * scale + 2, y * scale + 2},
      2,
      color
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
