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
    {:ok, assign_defaults(socket)}
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
    assign(socket, live_cells: initial_pattern(pattern, socket.assigns.grid_size))
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

    {:noreply, assign(socket, :live_cells, new_live_cells)}
  end

  def handle_event("start_stop", _, socket) do
    %{is_running: is_running, timer: timer, speed: speed} = socket.assigns

    new_socket =
      if is_running do
        # TODO: refactor this reset timer logic by extract into a private function
        # Stop the game and cancel the timer
        if timer, do: Process.cancel_timer(timer)
        assign(socket, is_running: false, timer: nil)
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
      {:noreply, tick_game(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("clear", _, socket) do
    socket.assigns.timer && Process.cancel_timer(socket.assigns.timer)

    new_socket =
      assign(socket,
        live_cells: MapSet.new(),
        is_running: false,
        generation: 0,
        timer: nil
      )

    {:noreply, new_socket}
  end

  def handle_event("set_speed", %{"speed" => speed_str}, socket) do
    speed = String.to_integer(speed_str)
    socket = assign(socket, :speed, speed)

    if socket.assigns.is_running do
      # Cancel the old timer and schedule a new one with the updated speed.
      socket.assigns.timer && Process.cancel_timer(socket.assigns.timer)

      {:noreply, assign_timer(socket, speed)}
    else
      {:noreply, socket}
    end
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

      # update game state
      socket =
        assign(socket,
          live_cells: cells,
          generation: 0,
          is_running: false
        )

      # TODO: refactor this reset timer logic by extract into a private function
      # cancel timer if running
      if socket.assigns.timer, do: Process.cancel_timer(socket.assigns.timer)
      socket = assign(socket, timer: nil)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp assign_timer(socket, speed) do
    assign(socket, timer: Process.send_after(self(), :tick, speed))
  end

  @impl true
  def handle_info(:tick, %{assigns: %{is_running: true, speed: speed}} = socket) do
    # The timer has fired. We run the game logic and schedule the next tick.
    socket =
      socket
      |> tick_game()
      |> assign_timer(speed)

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    {:noreply, socket}
  end

  defp tick_game(socket) do
    new_live_cells = Game.tick(socket.assigns.live_cells)

    assign(socket,
      live_cells: new_live_cells,
      generation: socket.assigns.generation + 1
    )
  end

  defp initial_pattern(pattern, grid_size) do
    pattern
    |> GameOfLife.Patterns.get_pattern(grid_size)
    |> GameOfLife.PatternUtils.center_pattern(grid_size)
  end

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
