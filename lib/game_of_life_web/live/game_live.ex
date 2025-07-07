defmodule GameOfLifeWeb.GameLive do
  use GameOfLifeWeb, :live_view

  alias GameOfLife.Game
  import GameOfLifeWeb.Components.PatternPreview, only: [pattern_preview: 1]

  # Default grid size
  @grid_size 100
  # Default speed in ms
  @default_speed 200

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_defaults()
      |> stream(:cells, [], dom_id: &cell_id/1)

    {:ok, socket}
  end

  defp assign_defaults(socket) do
    assign(socket,
      grid_size: @grid_size,
      is_running: false,
      speed: @default_speed,
      generation: 0,
      grid_style: grid_style_value(@grid_size),
      timer: nil,
      live_cells: MapSet.new(),
      preview_patterns: GameOfLife.Patterns.get_preview_patterns(),
      show_rle_input: false,
      rle_input: "",
      rle_preview_cells: nil
    )
  end

  defp assign_pattern(socket, pattern) do
    live_cells = initial_pattern(pattern, socket.assigns.grid_size)
    put_live_cells(socket, live_cells)
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      if connected?(socket) do
        # 客戶端已連接：載入完整互動功能
        # 這時候使用者瀏覽器已經準備好處理動態內容，不會影響首次顯示內容所需時間 (FCP)
        assign_pattern(socket, Map.get(params, "pattern"))
      else
        # 初始靜態渲染：優化 SEO 和核心網頁指標
        # 搜尋引擎爬蟲一進頁面就可直接抓到所有必要的內容與標籤（如標題、描述、圖片、文章內容等）
        # 可提升頁面排名和使用者體驗
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_cell", %{"x" => x_str, "y" => y_str}, socket) do
    cell = {String.to_integer(x_str), String.to_integer(y_str)}

    new_live_cells =
      if cell in socket.assigns.live_cells do
        MapSet.delete(socket.assigns.live_cells, cell)
      else
        MapSet.put(socket.assigns.live_cells, cell)
      end

    add_set = if cell in new_live_cells, do: [cell], else: []
    remove_set = if cell in socket.assigns.live_cells, do: [cell], else: []

    socket =
      socket
      |> assign(live_cells: new_live_cells)
      |> stream_apply_diff(add_set, remove_set)

    {:noreply, socket}
  end

  def handle_event("start_stop", _, socket) do
    %{is_running: is_running, speed: speed} = socket.assigns

    new_socket =
      if is_running do
        # Stop the game and cancel the timer
        socket
        |> assign(is_running: false)
        |> maybe_reset_timer()
      else
        # Start the game and schedule the first tick
        socket
        |> assign(is_running: true)
        |> assign_timer(speed)
      end

    {:noreply, new_socket}
  end

  def handle_event("next_step", _, socket) do
    if !socket.assigns.is_running do
      new_live_cells = Game.tick(socket.assigns.live_cells)
      socket = socket |> put_live_cells(new_live_cells) |> bump_generation()

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("clear", _, socket) do
    new_socket =
      socket
      |> maybe_reset_timer()
      |> assign(
        live_cells: MapSet.new(),
        is_running: false,
        generation: 0
      )

    {:noreply, new_socket}
  end

  def handle_event("set_speed", %{"speed" => speed_str}, socket) do
    speed = String.to_integer(speed_str)

    {:noreply,
     socket
     |> assign(:speed, speed)
     |> maybe_reset_timer()
     |> assign_timer(speed)}
  end

  def handle_event("toggle_rle_input", _, socket) do
    {:noreply, assign(socket, :show_rle_input, !socket.assigns.show_rle_input)}
  end

  def handle_event("preview_rle", %{"value" => rle}, socket) do
    preview_cells =
      if String.trim(rle) != "" do
        GameOfLife.Patterns.rle_to_cells(rle)
      else
        nil
      end

    {:noreply, assign(socket, rle_input: rle, rle_preview_cells: preview_cells)}
  end

  def handle_event("import_rle", _, %{assigns: %{rle_input: rle}} = socket) do
    if String.trim(rle) != "" do
      cells =
        rle
        |> GameOfLife.Patterns.rle_to_cells()
        |> GameOfLife.PatternUtils.center_pattern(socket.assigns.grid_size)

      add_set = MapSet.to_list(cells)
      remove_set = MapSet.to_list(socket.assigns.live_cells)

      socket = stream_apply_diff(socket, add_set, remove_set)

      socket =
        socket
        |> put_live_cells(cells)
        |> assign(
          generation: 0,
          is_running: false
        )
        |> maybe_reset_timer()

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp maybe_reset_timer(socket) do
    if timer = socket.assigns.timer do
      Process.cancel_timer(timer)
      assign(socket, :timer, nil)
    else
      socket
    end
  end

  defp assign_timer(socket, speed) do
    socket
    |> maybe_reset_timer()
    |> assign(timer: Process.send_after(self(), :tick, speed))
  end

  @impl true
  def handle_info(:tick, %{assigns: %{is_running: true, speed: speed}} = socket) do
    new_live_cells = Game.tick(socket.assigns.live_cells)
    socket = socket |> put_live_cells(new_live_cells) |> bump_generation()
    {:noreply, assign_timer(socket, speed)}
  end

  def handle_info(:tick, socket) do
    {:noreply, socket}
  end

  defp initial_pattern(pattern, grid_size) do
    # 計算網格中心點
    center_x = div(grid_size, 2)
    center_y = div(grid_size, 2)

    # Get pattern by pattern name
    pattern = GameOfLife.Patterns.get_pattern(pattern, grid_size)

    # Calculate pattern boundaries
    {min_x, max_x, min_y, max_y} = pattern_boundaries(pattern)

    # Calculate offset to center the pattern
    offset_x = center_x - div(min_x + max_x, 2)
    offset_y = center_y - div(min_y + max_y, 2)

    # Offset pattern coordinates
    pattern
    |> Enum.map(fn {x, y} -> {x + offset_x, y + offset_y} end)
    |> MapSet.new()
  end

  # Calculate pattern boundaries (minimum and maximum x, y coordinates)
  defp pattern_boundaries(pattern) do
    Enum.reduce(pattern, {999, -999, 999, -999}, fn {x, y}, {min_x, max_x, min_y, max_y} ->
      {
        min(min_x, x),
        max(max_x, x),
        min(min_y, y),
        max(max_y, y)
      }
    end)
  end

  defp cell_id({x, y}), do: "cell-#{x}-#{y}"

  defp bump_generation(socket) do
    assign(socket, generation: socket.assigns.generation + 1)
  end

  # LiveStream helpers --------------------------------------------------
  defp put_live_cells(socket, live_cells) do
    socket
    |> assign(live_cells: live_cells)
    |> stream_reset_cells(live_cells)
  end

  defp stream_reset_cells(socket, live_cells) do
    stream(socket, :cells, MapSet.to_list(live_cells), reset: true, dom_id: &cell_id/1)
  end

  defp stream_apply_diff(socket, add_set, remove_set) do
    socket = Enum.reduce(add_set, socket, fn cell, s -> stream_insert(s, :cells, cell, at: 0) end)
    Enum.reduce(remove_set, socket, fn cell, s -> stream_delete(s, :cells, cell) end)
  end

  # ---------------------------------------------------------------------
  def cell_class(cell, live_cells) do
    if cell in live_cells do
      "bg-black"
    else
      "bg-white hover:bg-gray-100"
    end
  end

  defp grid_style_value(grid_size) do
    "grid-template-columns: repeat(#{grid_size}, minmax(0, 1fr)); grid-template-rows: repeat(#{grid_size}, minmax(0, 1fr));"
  end
end
