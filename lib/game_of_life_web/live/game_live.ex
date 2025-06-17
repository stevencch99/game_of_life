defmodule GameOfLifeWeb.GameLive do
  use GameOfLifeWeb, :live_view

  alias GameOfLife.Game

  # Default grid size
  @grid_size 100
  # Default speed in ms
  @default_speed 200

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        grid_size: @grid_size,
        live_cells: initial_pattern(),
        is_running: false,
        speed: @default_speed,
        generation: 0,
        # Assign pre-calculated grid_style
        grid_style: grid_style_value(@grid_size)
      )

    {:ok, socket}
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
    is_running = socket.assigns.is_running
    new_socket = assign(socket, :is_running, !is_running)

    if !is_running do
      # Start the game
      Process.send_after(self(), :tick, new_socket.assigns.speed)
      # Evolve one step immediately when starting
      {:noreply, tick_game(new_socket)}
    else
      # Pause the game - the :tick handler will stop sending messages
      {:noreply, new_socket}
    end
  end

  def handle_event("next_step", _, socket) do
    if !socket.assigns.is_running do
      {:noreply, tick_game(socket)}
    else
      # Do nothing if game is running
      {:noreply, socket}
    end
  end

  def handle_event("clear", _, socket) do
    new_socket =
      assign(socket,
        live_cells: MapSet.new(),
        is_running: false,
        generation: 0
      )

    {:noreply, new_socket}
  end

  def handle_event("set_speed", %{"value" => speed_str}, socket) do
    {:noreply, assign(socket, :speed, String.to_integer(speed_str))}
  end

  @impl true
  def handle_info(:tick, %{assigns: %{is_running: true, speed: speed}} = socket) do
    Process.send_after(self(), :tick, speed)
    {:noreply, tick_game(socket)}
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

  defp initial_pattern do
    pattern_glider()
    # Or start empty: MapSet.new()
  end

  def pattern_glider do
    MapSet.new([{1, 0}, {2, 1}, {0, 2}, {1, 2}, {2, 2}])
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
