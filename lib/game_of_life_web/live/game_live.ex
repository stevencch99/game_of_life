defmodule GameOfLifeWeb.GameLive do
  use GameOfLifeWeb, :live_view

  alias GameOfLife.Game
  import GameOfLifeWeb.Components.PatternPreview, only: [pattern_preview: 1]

  defp normalize(v) when is_integer(v), do: v
  defp normalize(v) when is_binary(v), do: String.to_integer(v)
  defp normalize(v), do: v

  defp live_cells_to_list(cells) do
    # 將 live_cells MapSet 結構轉成 [[x, y], ...]，並確保 x、y 為整數以供前端使用
    MapSet.to_list(cells)
    |> Enum.flat_map(fn
      {x, y} -> [[normalize(x), normalize(y)]]
      [x, y] -> [[normalize(x), normalize(y)]]
      _ -> []
    end)
  end

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
      current_pattern: nil,
      preview_patterns: GameOfLife.Patterns.get_preview_patterns(),
      show_rle_input: false,
      rle_input: "",
      rle_preview_cells: nil
    )
  end

  defp assign_pattern(socket, nil), do: socket

  defp assign_pattern(socket, pattern) when is_binary(pattern) do
    live_cells = initial_pattern(pattern, socket.assigns.grid_size)

    socket
    |> assign(
      live_cells: live_cells,
      generation: 0,
      current_pattern: pattern
    )
    |> update_game_canvas(live_cells)
  end

  @impl true
  def handle_params(%{"pattern" => pattern}, _url, socket) do
    socket =
      socket
      |> assign(:current_pattern, pattern)
      |> assign_pattern(pattern)

    {:noreply, socket}
  end

  def handle_params(_params, _url, socket) do
    socket =
      if is_nil(socket.assigns[:current_pattern]) do
        assign(socket, :current_pattern, "glider")
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_cell", %{"x" => x, "y" => y}, socket) do
    x_int = if is_binary(x), do: String.to_integer(x), else: x
    y_int = if is_binary(y), do: String.to_integer(y), else: y
    cell = {x_int, y_int}

    new_live_cells =
      if MapSet.member?(socket.assigns.live_cells, cell) do
        MapSet.delete(socket.assigns.live_cells, cell)
      else
        MapSet.put(socket.assigns.live_cells, cell)
      end

    socket = assign(socket, live_cells: new_live_cells)

    {:noreply, update_game_canvas(socket, new_live_cells)}
  end

  def handle_event("start_stop", _, socket) do
    %{is_running: is_running, speed: speed, live_cells: _live_cells} = socket.assigns

    new_socket =
      if is_running do
        # Stop the game and cancel the timer
        socket
        |> assign(is_running: false)
        |> maybe_reset_timer()
      else
        # Start the game with current live cells and schedule the first tick
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

      # update game state
      socket =
        socket
        |> assign(
          live_cells: cells,
          generation: 0,
          is_running: false
        )
        |> maybe_reset_timer()
        |> update_game_canvas(cells)

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
    %{live_cells: current_cells, generation: generation} = socket.assigns

    new_live_cells = Game.tick(current_cells)

    socket
    |> assign(
      live_cells: new_live_cells,
      generation: generation + 1
    )
    |> update_game_canvas(new_live_cells)
  end

  @spec initial_pattern(binary() | atom(), integer()) :: MapSet.t()
  defp initial_pattern(pattern_name, grid_size) do
    pattern_name
    |> GameOfLife.Patterns.get_pattern(grid_size)
    |> GameOfLife.PatternUtils.center_pattern(grid_size)
  end

  defp grid_style_value(grid_size) do
    "grid-template-columns: repeat(#{grid_size}, minmax(0, 1fr)); grid-template-rows: repeat(#{grid_size}, minmax(0, 1fr));"
  end

  defp update_game_canvas(socket, live_cells) do
    push_event(socket, "update_cells", %{
      to: "#game-canvas",
      payload: %{live_cells: live_cells_to_list(live_cells)}
    })
  end
end
