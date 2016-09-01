defmodule ForestFireSim.Forest do
  @moduledoc ~S"""
  This model is the data representation of the simulation.  It keeps track of:

  * The width and height of the simulation space
  * The current locations of all trees and fires
  """

  defstruct width: nil, height: nil, locations: %{ }

  @max_intensity 4

  @doc ~S"""
  Returns the location an intensity of all current fires.

      iex> forest = ForestFireSim.Forest.from_string("&")
      iex> ForestFireSim.Forest.get_fires(forest)
      [{{0, 0}, 4}]
  """
  def get_fires(%__MODULE__{locations: locations}) do
    Stream.filter(locations, fn {_xy, location} ->
      is_tuple(location) and elem(location, 0) == :fire
    end)
    |> Enum.map(fn {xy, {:fire, intensity}} -> {xy, intensity} end)
  end

  @doc ~S"""
  This utility function returns what is currently at the location `xy`.  This is
  used in the tests.  The three possible return values are:

  * `:tree`
  * `{:fire, current_intensity}`
  * `nil`

      iex> forest = ForestFireSim.Forest.from_string("&* ")
      iex> ForestFireSim.Forest.get_location(forest, {0, 0})
      {:fire, 4}
      iex> ForestFireSim.Forest.get_location(forest, {1, 0})
      :tree
      iex> ForestFireSim.Forest.get_location(forest, {2, 0})
      nil
  """
  def get_location(%__MODULE__{locations: locations}, xy) do
    Map.get(locations, xy)
  end

  @doc ~S"""
  Reduces the intensity of a fire in the forest at `xy` until it cycles to
  extinction.

      iex> forest = ForestFireSim.Forest.from_string("&")
      iex> ForestFireSim.Forest.get_location(forest, {0, 0})
      {:fire, 4}
      iex> forest = ForestFireSim.Forest.reduce_fire(forest, {0, 0})
      iex> ForestFireSim.Forest.get_location(forest, {0, 0})
      {:fire, 3}
      iex> forest = ForestFireSim.Forest.reduce_fire(forest, {0, 0})
      iex> ForestFireSim.Forest.get_location(forest, {0, 0})
      {:fire, 2}
      iex> forest = ForestFireSim.Forest.reduce_fire(forest, {0, 0})
      iex> ForestFireSim.Forest.get_location(forest, {0, 0})
      {:fire, 1}
      iex> forest = ForestFireSim.Forest.reduce_fire(forest, {0, 0})
      iex> ForestFireSim.Forest.get_location(forest, {0, 0})
      nil
  """
  def reduce_fire(forest = %__MODULE__{locations: locations}, xy) do
    updated_locations =
      if Map.fetch!(locations, xy) == {:fire, 1} do
        Map.delete(locations, xy)
      else
        Map.update!(locations, xy, fn {:fire, intensity} ->
          {:fire, intensity - 1}
        end)
      end
    %__MODULE__{forest | locations: updated_locations}
  end

  @doc ~S"""
  This function spreads a fire to trees that are north, south, east, and west
  of `xy`.  It returns the new forest, and a list of new fires created.

      iex> forest = ForestFireSim.Forest.from_string("&* ")
      iex> ForestFireSim.Forest.get_location(forest, {1, 0})
      :tree
      iex> {forest, new_fires} = ForestFireSim.Forest.spread_fire(forest, {0, 0})
      iex> new_fires
      [{{1, 0}, 4}]
      iex> ForestFireSim.Forest.get_location(forest, {1, 0})
      {:fire, 4}
  """
  def spread_fire(forest = %__MODULE__{locations: locations}, xy) do
    {updated_locations, new_fires} =
      case Map.get(locations, xy) do
        {:fire, _intensity} ->
          neighbors(xy)
          |> Enum.reduce(
            {locations, [ ]},
            fn neighbor_xy, {with_new_fires, new_fires} ->
              if Map.get(with_new_fires, neighbor_xy) == :tree do
                {
                  Map.put(with_new_fires, neighbor_xy, {:fire, @max_intensity}),
                  [{neighbor_xy, @max_intensity} | new_fires]
                }
              else
                {with_new_fires, new_fires}
              end
            end
          )
        _ ->
          {locations, [ ]}
      end
    {%__MODULE__{forest | locations: updated_locations}, new_fires}
  end

  @doc ~S"""
  Returns a string representation of passed forest.  By default ANSI coloring
  is included, but passing `false` as the second argument disables this behavior.

      iex> "&* " |> ForestFireSim.Forest.from_string |> ForestFireSim.Forest.to_string(false)
      "&* "
  """
  def to_string(
    %__MODULE__{width: width, height: height, locations: locations},
    ansi? \\ true
  ) do
    string =
      Enum.map(0..(height - 1), fn y ->
        Enum.map(0..(width - 1), fn x ->
          Map.get(locations, {x, y})
          |> to_location_string
          |> IO.ANSI.format(ansi?)
        end)
        |> Enum.join
      end)
      |> Enum.join("\n")
    IO.ANSI.format_fragment([:clear, :home, string], ansi?)
    |> IO.chardata_to_string
  end

  @doc """
  This is a utility function that builds known forest layouts.  It's used in the
  test.  For example:

      iex> ForestFireSim.Forest.from_string(
      iex>   \"""
      iex>   &**
      iex>    **
      iex>   \"""
      iex> )
      %ForestFireSim.Forest{width: 3, height: 2, locations: %{{0, 0} => {:fire, 4}, {1, 0} => :tree, {1, 1} => :tree, {2, 0} => :tree, {2, 1} => :tree}}
  """
  def from_string(string) do
    rows = String.split(string, "\n", trim: true)
    width = rows |> hd |> String.length
    height = length(rows)

    unless Enum.all?(rows, fn row -> String.length(row) == width end) do
      raise "All rows needs the same width"
    end

    locations =
      rows
      |> Enum.with_index
      |> Enum.reduce(%{ }, fn {row, y}, map ->
        row
        |> String.graphemes
        |> Enum.with_index
        |> Enum.reduce(map, fn {char, x}, row_map ->
          location =
            case char do
              "*" -> :tree
              "&" -> {:fire, @max_intensity}
              _ -> nil
            end
          if location do
            Map.put(row_map, {x, y}, location)
          else
            row_map
          end
        end)
      end)
    %__MODULE__{width: width, height: height, locations: locations}
  end

  @doc ~S"""
  This function generates a new forest with the passed `:width` and `:height`.
  Roughly `:percent` of the locations in the generated forest will be filled.
  A filled location on the far left side will be a fire, but all other filled
  locations will be trees.

      ForestFireSim.Forest.generate(%{width: 80, height: 24, percent: 66})
  """
  def generate(%{width: width, height: height, percent: percent}) do
    locations =
      for x <- 0..(width - 1),
          y <- 0..(height - 1),
          :rand.uniform(100) <= percent,
          into: %{ } do
        location = if x == 0, do: {:fire, @max_intensity}, else: :tree
        {{x, y}, location}
      end
    %__MODULE__{width: width, height: height, locations: locations}
  end

  defp neighbors({x, y}) do
    [             {x, y - 1},
      {x - 1, y},             {x + 1, y},
                  {x, y + 1} ]
  end

  defp to_location_string(:tree),      do: [:green, "*"]
  defp to_location_string({:fire, 4}), do: [:bright, :red, "&"]
  defp to_location_string({:fire, 3}), do: [:red, "&"]
  defp to_location_string({:fire, 2}), do: [:bright, :yellow, "&"]
  defp to_location_string({:fire, 1}), do: [:yellow, "&"]
  defp to_location_string(nil),        do: " "
end
