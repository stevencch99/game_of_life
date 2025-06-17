# This file will contain the LiveView logic for the Game of Life.
defmodule GameOfLifeWeb.GameLive do
  use GameOfLifeWeb, :live_view

  alias GameOfLife.Game

  @impl true
  def mount(_params, _session, socket) do
    # TODO: Initialize game state: grid_size, live_cells, is_running, speed
    socket = assign(socket, 
      grid_size: 30, 
      live_cells: MapSet.new([{1,2}, {2,3}, {3,1}, {3,2}, {3,3}]), # Example: Glider
      is_running: false,
      speed: 200,
      generation: 0
    )
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    # TODO: Render the game grid and controls using game_live.html.heex
    ~H"""
    <div>Game of Life LiveView - Placeholder</div>
    """
  end

  # TODO: Implement handle_event for user interactions
  # - toggle_cell
  # - start_stop
  # - next_step
  # - clear
  # - set_speed

  # TODO: Implement handle_info for game ticks
  # - :tick
end
