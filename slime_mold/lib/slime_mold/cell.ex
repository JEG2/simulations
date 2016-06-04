defmodule SlimeMold.Cell do
  defstruct board_size: nil, xy: nil, angle: 0, rand_state: nil

  # Client API

  def start do
    delay = Application.fetch_env!(:slime_mold, :cell_delay)

    init
    |> run(delay)
  end

  # Server API

  defp init do
    <<a::32, b::32, c::32>> = :crypto.rand_bytes(12)
    rand_state = :rand.seed_s(:exs1024, {a, b, c})

    board_size = {width, height} = SlimeMold.Board.get_size
    {x, rand_state} = :rand.uniform_s(width, rand_state)
    {y, rand_state} = :rand.uniform_s(height, rand_state)

    xy = {x - 1, y - 1}
    SlimeMold.Board.place_cell(xy)

    %__MODULE__{board_size: board_size, xy: xy, rand_state: rand_state}
  end

  defp run(cell, delay) do
    :timer.sleep(delay)

    cell
    |> wander
    |> drop_pheromone
    |> run(delay)
  end

  defp wander(
    cell = %__MODULE__{
      board_size: {width, height},
      xy: xy = {x, y},
      angle: angle
    }
  ) do
    possible_xys =
      [wrap(angle - 1, 8), angle, wrap(angle + 1, 8)]
      |> Enum.map(fn possible_angle ->
        {x_offset, y_offset} = offsets(possible_angle)
        {{wrap(x + x_offset, width), wrap(y + y_offset, height)}, possible_angle}
      end)
      |> Enum.into(Map.new)
    possible_moves =
      SlimeMold.Board.sniff(Map.keys(possible_xys))
      |> Enum.map(fn {possible_xy, pheromone} ->
        {possible_xy, Float.floor(pheromone + 0.0) |> trunc}
      end)
    best =
      Enum.max_by(possible_moves, fn {_xy, pheromone} -> pheromone end)
      |> elem(1)
    move =
      Enum.filter(possible_moves, fn {_xy, pheromone} -> pheromone == best end)
      |> Enum.random
      |> elem(0)
    SlimeMold.Board.move_cell(xy, move)
    %__MODULE__{cell | xy: move, angle: Map.fetch!(possible_xys, move)}
  end

  defp offsets(0), do: {0, -1}
  defp offsets(1), do: {1, -1}
  defp offsets(2), do: {1, 0}
  defp offsets(3), do: {1, 1}
  defp offsets(4), do: {0, 1}
  defp offsets(5), do: {-1, 1}
  defp offsets(6), do: {-1, 0}
  defp offsets(7), do: {-1, -1}

  defp wrap(value, limit), do: rem(limit + value, limit)

  defp drop_pheromone(cell = %__MODULE__{xy: xy}) do
    SlimeMold.Board.increase_pheromone(xy)
    cell
  end
end
