defmodule TurtlesAndFrogs.Critter do
  # Client API

  def start(xy, type, size) do
    loop(xy, neighbors_for(xy, size), type, size)
  end

  # Helpers

  defp loop(xy, neighbor_xys, type, size) do
    :timer.sleep(333)

    if happy?(neighbor_xys, type) do
      loop(xy, neighbor_xys, type, size)
    else
      move_away_from(xy, type, size) |> loop(neighbor_xys, type, size)
    end
  end

  defp neighbors_for({x, y}, size = {width, height}) do
    [ {-1, -1}, {0, -1}, {1, -1},
      {-1,  0},          {1,  0},
      {-1,  1}, {0,  1}, {1,  1} ]
    |> Enum.map(fn {x_offset, y_offset} ->
      {rem(width + (x + x_offset), width), rem(height + (y + y_offset), height)}
    end)
    |> Enum.filter(fn new_xy -> valid?(new_xy, size) end)
  end

  defp valid?({new_x, new_y}, {width, height}) do
    new_x >= 0 and new_x < width and new_y >= 0 and new_y < height
  end

  defp happy?(neighbor_xys, type) do
    neighbors = TurtlesAndFrogs.Pond.look_around(neighbor_xys, type)
    Enum.sum(neighbors) >= length(neighbors) * 0.3
  end

  defp move_away_from(xy, type, size) do
    possible_xy =
      :rand.uniform(8)
      |> heading_to_direction
      |> advance(xy, :rand.uniform(5))
    if valid?(possible_xy, size) do
      TurtlesAndFrogs.Pond.try_move(xy, possible_xy, type)
    else
      xy
    end
  end

  defp heading_to_direction(1), do: {0, -1}
  defp heading_to_direction(2), do: {1, -1}
  defp heading_to_direction(3), do: {1, 0}
  defp heading_to_direction(4), do: {1, 1}
  defp heading_to_direction(5), do: {0, 1}
  defp heading_to_direction(6), do: {-1, 1}
  defp heading_to_direction(7), do: {-1, 0}
  defp heading_to_direction(8), do: {-1, -1}

  defp advance({x_offset, y_offset}, {x, y}, distance) do
    {x + x_offset * distance, y + y_offset * distance}
  end
end
