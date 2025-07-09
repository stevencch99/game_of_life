defmodule GameOfLifeWeb.Components.PatternPreview do
  use Phoenix.Component

  attr :pattern, :map, required: true, doc: "The pattern data to preview"
  attr :size, :integer, default: 80, doc: "The size of the preview in pixels"
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :padding, :integer, default: 1, doc: "Padding around the pattern (in viewBox units)"

  attr :max_view_size, :integer,
    default: 20,
    doc: "Maximum viewBox dimension in grid cells (SVG coordinate units)"

  def pattern_preview(assigns) do
    assigns = assign_cell_positions(assigns)

    ~H"""
    <svg width={@size} height={@size} viewBox={@view_box} class={["pattern-preview", @class]}>
      <!-- grid -->
      <rect x="0" y="0" width="100%" height="100%" fill="white" stroke="#eee" stroke-width="0.1" />
      
    <!-- cells -->
      <rect
        :for={{x, y} <- @precomputed_cells}
        x={x}
        y={y}
        width={@cell_size}
        height={@cell_size}
        fill="black"
      />
    </svg>
    """
  end

  # 計算所有必要的變數和細胞位置
  defp assign_cell_positions(assigns) do
    %{pattern: pattern, max_view_size: max_view_size, padding: padding} = assigns

    {min_x, max_x, min_y, max_y} =
      GameOfLife.PatternUtils.pattern_boundaries(pattern.cells)

    width = max(1, max_x - min_x + 1)
    height = max(1, max_y - min_y + 1)

    # 計算需要的 viewBox 大小（加上 padding）
    view_width = min(max_view_size, width + 2 * padding)
    view_height = min(max_view_size, height + 2 * padding)

    # 計算縮放因子，使 pattern 適合預覽區域
    scale =
      min(
        (view_width - 2 * padding) / width,
        (view_height - 2 * padding) / height
      )

    # 計算偏移，使 pattern 居中
    offset_x = (view_width - width * scale) / 2
    offset_y = (view_height - height * scale) / 2

    # 計算單元格大小（稍微縮小以便有間隔）
    cell_size = scale * 0.9

    # 計算所有細胞的顯示座標
    precomputed_cells =
      Enum.map(pattern.cells, fn {x, y} ->
        preview_x = (x - min_x) * scale + offset_x
        preview_y = (y - min_y) * scale + offset_y
        {preview_x, preview_y}
      end)

    # 將必要的顯示變數放入 assigns
    assign(assigns,
      cell_size: cell_size,
      view_box: "0 0 #{view_width} #{view_height}",
      precomputed_cells: precomputed_cells
    )
  end
end
