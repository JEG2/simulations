defmodule ForestTest do
  alias ForestFireSim.Forest

  use ExUnit.Case, async: true
  doctest Forest

  test "can be constructed from strings" do
    forest = Forest.from_string("&* ")
    assert Forest.get_location(forest, {0, 0}) == {:fire, 4}
    assert Forest.get_location(forest, {1, 0}) == :tree
    assert Forest.get_location(forest, {2, 0}) == nil
  end

  test "construction errors out if widths are inconsistent" do
    assert_raise RuntimeError, fn ->
      Forest.from_string(
        """
        ***
        **
        """
      )
    end
  end

  test "can be stringified" do
    string = "&* "
    assert string |> Forest.from_string |> Forest.to_string(false) == string
  end

  test "is stringified with ANSI colors by default" do
    stringified = "&* " |> Forest.from_string |> Forest.to_string
    colored = IO.ANSI.format_fragment(
      [:clear, :home,
       IO.ANSI.format([:bright, :red, "&"]),
       IO.ANSI.format([:green, "*"]),
       " "]
    ) |> IO.chardata_to_string
    assert stringified == colored
  end

  test "can be generated from statistics" do
    empty =
      Forest.generate(%{width: 2, height: 1, percent: 0})
      |> Forest.to_string(false)
    assert empty == "  "

    full =
      Forest.generate(%{width: 2, height: 1, percent: 100})
      |> Forest.to_string(false)
    assert full == "&*"
  end

  test "can return all fires" do
    actual = Forest.from_string(
      """
      & *
      * &
      """
    )
    |> Forest.get_fires
    |> Enum.sort_by(fn {{x, y}, _location} -> [x, y] end)
    expected = [{{0, 0}, 4}, {{2, 1}, 4}]
    assert actual == expected
  end

  test "can reduce a fires intensity" do
    forest =
      [4, 3, 2, 1]
      |> Enum.reduce(Forest.from_string("&"), fn intensity, reduced_forest ->
        assert Forest.get_location(reduced_forest, {0, 0}) == {:fire, intensity}
        Forest.reduce_fire(reduced_forest, {0, 0})
      end)
    assert Forest.get_location(forest, {0, 0}) == nil
  end

  test "can spread fires" do
    spread = fn forest, xy ->
      {forest, fires} = Forest.spread_fire(forest, xy)
      sorted_fires = Enum.sort_by(fires, fn {{x, y}, _location} -> [x, y] end)
      {forest, sorted_fires}
    end
    forest = Forest.from_string(
      """
      ***
      *&*
      ***
      """
    )

    {forest, new_fires} = spread.(forest, {1, 1})
    expected_forest =
      String.trim(
        """
        *&*
        &&&
        *&*
        """
      )
    expected_fires = [{{0, 1}, 4}, {{1, 0}, 4}, {{1, 2}, 4}, {{2, 1}, 4}]
    assert Forest.to_string(forest, false) == expected_forest
    assert new_fires == expected_fires

    {forest, new_fires} = spread.(forest, {1, 0})
    expected_forest =
      String.trim(
        """
        &&&
        &&&
        *&*
        """
      )
    expected_fires = [{{0, 0}, 4}, {{2, 0}, 4}]
    assert Forest.to_string(forest, false) == expected_forest
    assert new_fires == expected_fires

    {forest, new_fires} = spread.(forest, {2, 1})
    expected_forest =
      String.trim(
        """
        &&&
        &&&
        *&&
        """
      )
    expected_fires = [{{2, 2}, 4}]
    assert Forest.to_string(forest, false) == expected_forest
    assert new_fires == expected_fires

    {forest, new_fires} = spread.(forest, {2, 2})
    assert Forest.to_string(forest, false) == expected_forest
    assert new_fires == [ ]
  end
end
