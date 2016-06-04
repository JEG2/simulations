defmodule SlimeMold.Environment do
  # Client API

  def start do
    delay = Application.fetch_env!(:slime_mold, :environment_delay)

    run(delay)
  end

  # Server API

  defp run(delay) do
    :timer.sleep(delay)

    evaporate
    diffuse

    run(delay)
  end

  defp evaporate do
    SlimeMold.Board.evaporate_all
  end

  defp diffuse do
    SlimeMold.Board.diffuse_all
  end
end
