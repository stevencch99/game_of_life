defmodule GameOfLife.Patterns do
  @doc """
  Get pattern by pattern name, fallback to random pattern if pattern not found.

  ## Parameters

    - pattern: pattern name, can be binary or atom
    - grid_size: grid size

  ## Examples

      iex> GameOfLife.Patterns.get_pattern("glider", 100)
      MapSet.new([{1, 0}, {2, 1}, {0, 2}, {1, 2}, {2, 2}])
  """
  @spec get_pattern(binary() | atom() | nil, integer()) :: MapSet.t()
  def get_pattern(nil, grid_size) do
    # When pattern is nil, return a random pattern
    random(grid_size)
  end

  def get_pattern(pattern, grid_size) when is_binary(pattern) do
    with {:ok, atom} <- safe_to_atom(pattern),
         true <- function_exported?(__MODULE__, atom, 0) do
      apply(__MODULE__, atom, [])
    else
      _ -> random(grid_size)
    end
  end

  defp safe_to_atom(str) do
    try do
      {:ok, String.to_existing_atom(str)}
    rescue
      ArgumentError -> :error
    end
  end

  @spec glider() :: MapSet.t()
  def glider do
    MapSet.new([{1, 0}, {2, 1}, {0, 2}, {1, 2}, {2, 2}])
  end

  @spec block() :: MapSet.t()
  def block do
    MapSet.new([{0, 0}, {0, 1}, {1, 0}, {1, 1}])
  end

  @spec beehive() :: MapSet.t()
  def beehive do
    MapSet.new([{0, 1}, {1, 0}, {1, 2}, {2, 1}, {3, 1}, {2, 2}])
  end

  @spec loaf() :: MapSet.t()
  def loaf do
    MapSet.new([{0, 2}, {1, 0}, {1, 2}, {2, 1}, {2, 3}, {3, 1}, {3, 2}])
  end

  @spec blinker() :: MapSet.t()
  def blinker do
    MapSet.new([{0, 0}, {0, 1}, {0, 2}])
  end

  @spec toad() :: MapSet.t()
  def toad do
    MapSet.new([{0, 1}, {1, 0}, {1, 1}, {1, 2}, {2, 1}, {2, 2}])
  end

  @spec beacon() :: MapSet.t()
  def beacon do
    MapSet.new([{0, 0}, {0, 1}, {1, 0}, {1, 1}, {2, 2}, {2, 3}, {3, 2}, {3, 3}])
  end

  @spec puffer() :: MapSet.t()
  def puffer do
    MapSet.new([{0, 0}, {0, 1}, {0, 2}, {1, 0}, {1, 2}, {2, 0}, {2, 1}, {2, 2}])
  end

  @spec r_pentomino() :: MapSet.t()
  def r_pentomino do
    MapSet.new([{0, 1}, {1, 0}, {1, 1}, {1, 2}, {2, 1}])
  end

  @spec diehard() :: MapSet.t()
  def diehard do
    MapSet.new([{0, 0}, {1, 0}, {2, 0}, {3, 1}, {4, 2}, {5, 2}, {6, 2}])
  end

  @spec acorn() :: MapSet.t()
  def acorn do
    MapSet.new([{0, 0}, {1, 1}, {2, 2}, {3, 0}, {4, 2}, {5, 2}, {6, 2}])
  end

  @spec pentadecathlon() :: MapSet.t()
  def pentadecathlon do
    MapSet.new([
      {0, 0},
      {0, 1},
      {0, 2},
      {0, 3},
      {0, 4},
      {1, 0},
      {1, 1},
      {1, 2},
      {1, 3},
      {1, 4},
      {2, 0},
      {2, 1},
      {2, 2},
      {2, 3},
      {2, 4}
    ])
  end

  @spec glider_gun() :: MapSet.t()
  def glider_gun do
    MapSet.new([
      {25, 1},
      {23, 2},
      {13, 2},
      {12, 1},
      {12, 0},
      {11, 0},
      {11, 1},
      {10, 1},
      {10, 2},
      {10, 3},
      {9, 3},
      {9, 2},
      {8, 2},
      {7, 1},
      {6, 2},
      {4, 2},
      {3, 2},
      {2, 1},
      {2, 0},
      {1, 0},
      {1, 1},
      {0, 1},
      {0, 0}
    ])
  end

  @spec tower() :: MapSet.t()
  def tower do
    rle_to_cells("3o$bob$o!")
  end

  @spec random_existing_pattern() :: MapSet.t()
  defp random_existing_pattern do
    ~w[
      glider
      block
      beehive
      loaf
      blinker
      toad
      beacon
      puffer
      r_pentomino
      diehard
      acorn
    ]a
    |> Enum.random()
    |> then(&apply(__MODULE__, &1, []))
  end

  @spec random(integer()) :: MapSet.t()
  def random(grid_size) do
    # 50% chance to use a random existing pattern
    if :rand.uniform() < 0.5 do
      random_existing_pattern()
    else
      total_random_cells(grid_size)
    end
  end

  @spec total_random_cells(integer()) :: MapSet.t()
  defp total_random_cells(grid_size) do
    # Use a smaller range to generate cells, so that interesting patterns can form in the central area
    # Use 1/5 of the grid size as the generation range, and about 1/3 of the cells in this range will be live cells

    # Calculate the generation area size and cell count
    area_size = div(grid_size, 5)
    cells_count = div(area_size * area_size, 3)

    # Try to avoid the performance loss of generating duplicate coordinates and then removing them
    Stream.repeatedly(fn ->
      # Random coordinates
      {
        :rand.uniform(area_size) - 1,
        :rand.uniform(area_size) - 1
      }
    end)
    |> Enum.take(cells_count)
    |> MapSet.new()
  end
end
