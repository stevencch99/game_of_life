defmodule GameOfLife.PatternUtils do
  @moduledoc """
  Tools for pattern, such as boundary calculation, centering, etc.
  """

  @doc """
  Calculate pattern boundaries (minimum and maximum x, y coordinates)

  ## Parameters
    - cells: MapSet 格式的座標集合

  ## Returns
    - {min_x, max_x, min_y, max_y} tuple
  """
  @spec pattern_boundaries(MapSet.t()) :: {integer(), integer(), integer(), integer()}
  def pattern_boundaries(cells) do
    Enum.reduce(cells, {999, -999, 999, -999}, fn {x, y}, {min_x, max_x, min_y, max_y} ->
      {
        min(min_x, x),
        max(max_x, x),
        min(min_y, y),
        max(max_y, y)
      }
    end)
  end

  @doc """
  Center the pattern in a specified grid size

  ## Parameters
    - pattern: MapSet 格式的座標集合
    - grid_size: 網格大小

  ## Returns
    - centered_cells: 置中後的 MapSet 座標集合
  """
  @spec center_pattern(MapSet.t(), integer()) :: MapSet.t()
  def center_pattern(pattern, grid_size) do
    center_x = div(grid_size, 2)
    center_y = div(grid_size, 2)

    {min_x, max_x, min_y, max_y} = pattern_boundaries(pattern)

    # 計算偏移量以置中圖案
    offset_x = center_x - div(min_x + max_x, 2)
    offset_y = center_y - div(min_y + max_y, 2)

    # 偏移圖案座標
    pattern
    |> Enum.map(fn {x, y} -> {x + offset_x, y + offset_y} end)
    |> MapSet.new()
  end
end
