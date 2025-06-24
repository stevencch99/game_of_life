defmodule GameOfLifeWeb.GameLive do
  use GameOfLifeWeb, :live_view

  alias GameOfLife.Game

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
      live_cells: MapSet.new()
    )
  end

  defp assign_pattern(socket, pattern) do
    assign(socket, live_cells: initial_pattern(pattern, socket.assigns.grid_size))
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      if connected?(socket) do
        assign_pattern(socket, Map.get(params, "pattern"))
      else
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

  def cell_class(cell, live_cells) do
    if cell in live_cells do
      "bg-black"
    else
      "bg-white hover:bg-gray-100"
    end
  end

  defp grid_style_value(grid_size) do
    "display: grid; grid-template-columns: repeat(#{grid_size}, minmax(0, 1fr)); grid-template-rows: repeat(#{grid_size}, minmax(0, 1fr)); width: min(80vw, 600px); height: min(80vw, 600px); border: 1px solid #ccc; aspect-ratio: 1/1;"
  end
end
