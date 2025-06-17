defmodule GameOfLife.Game do
  @moduledoc """
  Handles the core logic for Conway's Game of Life.
  The game state is represented by a MapSet of {x, y} tuples for live cells.
  """

  @doc """
  Calculates the 8 neighbors of a given cell.

  ## Examples

      iex> GameOfLife.Game.neighbors({1, 1})
      [{0, 0}, {0, 1}, {0, 2}, {1, 0}, {1, 2}, {2, 0}, {2, 1}, {2, 2}]

  """
  def neighbors({x, y}) do
    for dx <- [-1, 0, 1],
        dy <- [-1, 0, 1],
        not (dx == 0 && dy == 0) do
      {x + dx, y + dy}
    end
  end

  @doc """
  Computes the next generation of live cells based on Conway's rules.

  Rules:
  1. Any live cell with fewer than 2 live neighbours dies (underpopulation).
  2. Any live cell with 2 or 3 live neighbours lives on to the next generation.
  3. Any live cell with more than 3 live neighbours dies (overpopulation).
  4. Any dead cell with exactly 3 live neighbours becomes a live cell (reproduction).

  ## Examples

      iex> GameOfLife.Game.tick(MapSet.new([{1,0}, {1,1}, {1,2}])) # Blinker
      MapSet.new([{0,1}, {1,1}, {2,1}])

  """
  def tick(live_cells) when is_struct(live_cells, MapSet) do
    live_cells
    |> calculate_candidates()
    |> Enum.filter(&survives?(&1, live_cells))
    |> MapSet.new()
  end

  # Find all cells that need to be considered for the next generation.
  # This includes all live cells and their neighbors.
  defp calculate_candidates(live_cells) do
    live_cells
    |> Enum.flat_map(&neighbors/1)
    |> Enum.uniq()
    |> MapSet.new()
    |> MapSet.union(live_cells)
  end

  defp count_live_neighbors(cell, live_cells) do
    cell
    |> neighbors()
    |> Enum.count(&(&1 in live_cells))
  end

  defp survives?(cell, live_cells) do
    live_neighbor_count = count_live_neighbors(cell, live_cells)
    is_alive = cell in live_cells

    # A cell survives/is born if:
    # 1. It's alive and has 2 or 3 neighbors.
    # OR
    # 2. It's dead and has exactly 3 neighbors.
    (is_alive and live_neighbor_count in [2, 3]) or
      (!is_alive and live_neighbor_count == 3)
  end
end
