defmodule SlimeMold.Board do
  @empty_changes %{cells: MapSet.new, pheromones: %{ }, blanks: MapSet.new}

  defstruct size: nil,
            cells: %{ },
            pheromones: %{ },
            changes: Map.put(@empty_changes, :background, true)

  # Client API

  def start_link(size = {width, height})
  when is_integer(width) and width > 0 and is_integer(height) and height > 0 do
    Agent.start_link(fn -> init(size) end, name:  __MODULE__)
  end

  def get_size do
    Agent.get(__MODULE__, &handle_get_size/1)
  end

  def get_changed do
    Agent.get_and_update(__MODULE__, &handle_get_changed/1)
  end

  def place_cell(xy = {x, y})
  when is_integer(x) and x >= 0 and is_integer(y) and y >= 0 do
    Agent.update(__MODULE__, fn struct -> handle_place_cell(struct, xy) end)
  end

  def sniff(xys) when is_list(xys) do
    Enum.map(xys, fn
      xy = {x, y} when is_integer(x) and x >= 0 and is_integer(y) and y >= 0 ->
        {xy, Agent.get(__MODULE__, fn struct -> handle_sniff(struct, xy) end)}
    end)
  end

  def move_cell(from = {fx, fy}, to = {tx, ty})
  when is_integer(fx) and fx >= 0 and is_integer(fy) and fy >= 0
  and is_integer(tx) and tx >= 0 and is_integer(ty) and ty >= 0 do
    Agent.update(__MODULE__, fn struct -> handle_move_cell(struct, from, to) end)
  end

  def increase_pheromone(xy = {x, y})
  when is_integer(x) and x >= 0 and is_integer(y) and y >= 0 do
    Agent.update(__MODULE__, fn struct ->
      handle_increase_pheromone(struct, xy)
    end)
  end

  def evaporate_all do
    Agent.update(__MODULE__, &handle_evaporate_all/1)
  end

  def diffuse_all do
    Agent.update(__MODULE__, &handle_diffuse_all/1)
  end

  # Server API

  defp init(size) do
    cells = Application.fetch_env!(:slime_mold, :cells)

    Stream.repeatedly(fn ->
      Task.Supervisor.start_child(SlimeMold.Actives, &SlimeMold.Cell.start/0)
    end) |> Enum.take(cells)
    Task.Supervisor.start_child(
      SlimeMold.Actives,
      &SlimeMold.Environment.start/0
    )

    %__MODULE__{size: size}
  end

  defp handle_get_size(%__MODULE__{size: size}), do: size

  defp handle_get_changed(board = %__MODULE__{changes: changes}) do
    {changes, %__MODULE__{board | changes: @empty_changes}}
  end

  defp handle_place_cell(
    board = %__MODULE__{cells: cells, changes: changes},
    xy
  ) do
    %__MODULE__{
      board |
      cells: Map.update(cells, xy, 1, &(&1 + 1)),
      changes: change_cell(changes, xy)
    }
  end

  defp handle_sniff(%__MODULE__{pheromones: pheromones}, xy) do
    Map.get(pheromones, xy, {0, nil}) |> elem(0)
  end

  defp handle_move_cell(
    board = %__MODULE__{cells: cells, pheromones: pheromones, changes: changes},
    from,
    to
  ) do
    {from_cells, from_changes} =
      case Map.fetch!(cells, from) do
        1 ->
          changed =
            case Map.get(pheromones, from) do
              {value, _category} ->
                %{changes | pheromones: Map.put(changes.pheromones, from, value)}
              nil ->
                %{changes | blanks: MapSet.put(changes.blanks, from)}
            end
          {Map.delete(cells, from), changed}
        n when n > 1 ->
          {Map.put(cells, from, n - 1), changes}
        _ ->
          raise "Cell count too low"
      end
    {to_changed, new_cells} = Map.get_and_update(from_cells, to, fn current ->
      {is_nil(current), (current || 0) + 1}
    end)
    new_changes =
      if to_changed do
        change_cell(from_changes, to)
      else
        from_changes
      end
    %__MODULE__{board | cells: new_cells, changes: new_changes}
  end

  defp handle_increase_pheromone(
    board = %__MODULE__{cells: cells, pheromones: pheromones, changes: changes},
    xy
  ) do
    {value, category} = Map.get(pheromones, xy, {0, nil})
    new_value = value + 1.0
    new_category = Float.floor(new_value) |> trunc
    new_pheromones = Map.put(pheromones, xy, {new_value, new_category})
    new_changes =
      cond do
        new_category == category -> changes
        Map.has_key?(cells, xy) -> changes
        true ->
          %{changes | pheromones: Map.put(changes.pheromones, xy, new_value)}
      end
    %__MODULE__{board | pheromones: new_pheromones, changes: new_changes}
  end

  defp handle_evaporate_all(
    board = %__MODULE__{cells: cells, pheromones: pheromones, changes: changes}
  ) do
    {new_pheromones, new_changes} =
      Enum.reduce(
        pheromones,
        {pheromones, changes},
        fn {xy, {value, category}}, {evaporated, changed} ->
          new_value = value * 0.9
          new_category = Float.floor(new_value) |> trunc
          with_new_pheromone =
            if new_value < 0.1 do
              Map.delete(evaporated, xy)
            else
              Map.put(evaporated, xy, {new_value, new_category})
            end
          with_new_change =
            cond do
              new_value < 0.1 ->
                %{changed | blanks: MapSet.put(changed.blanks, xy)}
              new_category == category ->
                changed
              Map.has_key?(cells, xy) ->
                changed
              true ->
                %{ changed |
                   pheromones: Map.put(changed.pheromones, xy, new_value) }
            end
          {with_new_pheromone, with_new_change}
        end
      )
    %__MODULE__{board | pheromones: new_pheromones, changes: new_changes}
  end

  defp handle_diffuse_all(
    board = %__MODULE__{
      size: size,
      cells: cells,
      pheromones: pheromones,
      changes: changes
    }
  ) do
    new_pheromones =
      reduce_for_diffusion(Map.keys(pheromones), pheromones, %{ }, size)
      |> add_for_dissusion
    new_changes =
      calculate_diffusion_changes(cells, pheromones, changes, new_pheromones)
    %__MODULE__{board | pheromones: new_pheromones, changes: new_changes}
  end

  # Helpers

  defp change_cell(changes = %{cells: cells}, xy) do
    %{changes | cells: MapSet.put(cells, xy)}
  end

  defp reduce_for_diffusion([xy | rest], pheromones, additions, size) do
    {amount, new_pheromones} =
      Map.get_and_update!(pheromones, xy, fn {value, _category} ->
        diffusion = value * 0.2
        new_value = value - diffusion
        new_category = Float.floor(new_value) |> trunc
        {diffusion / 8, {new_value, new_category}}
      end)
    new_additions =
      xy
      |> neighbors(size)
      |> Enum.reduce(additions, fn neighbor_xy, added ->
        Map.update(added, neighbor_xy, amount, &(&1 + amount))
      end)
    reduce_for_diffusion(rest, new_pheromones, new_additions, size)
  end
  defp reduce_for_diffusion([ ], pheromones, additions, _size) do
    {Map.keys(additions), pheromones, additions}
  end

  defp neighbors({x, y}, {width, height}) do
    [ {-1, -1}, {0, -1}, {1, -1},
      {-1,  0},          {1,  0},
      {-1,  1}, {0,  1}, {1,  1} ]
    |> Enum.map(fn {x_offset, y_offset} ->
      {rem(width + (x + x_offset), width), rem(height + (y + y_offset), height)}
    end)
  end

  defp add_for_dissusion({xys, pheromones, additions}) do
    Enum.reduce(xys, pheromones, fn xy, new_pheromones ->
      new_value = Map.fetch!(additions, xy)
      new_category = Float.floor(new_value) |> trunc
      Map.update(
        new_pheromones,
        xy,
        {new_value, new_category},
        fn {value, _category} ->
          {value + new_value, new_category}
        end
      )
    end)
  end

  defp calculate_diffusion_changes(cells, pheromones, changes, new_pheromones) do
    Enum.reduce(
      new_pheromones,
      changes,
      fn {xy, {new_value, new_category}}, new_changes ->
        category = Map.get(pheromones, xy, {0, nil}) |> elem(1)
        cond do
          new_category == category ->
            new_changes
          Map.has_key?(cells, xy) ->
            new_changes
          true ->
            %{ new_changes |
               pheromones: Map.put(new_changes.pheromones, xy, new_value) }
        end
      end
    )
  end
end
