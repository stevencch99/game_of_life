defmodule GameOfLife.Patterns do
  defmodule Pattern do
    @moduledoc """
    Pattern struct, which contains the pattern name, description, category, and cells data
    used to represent a pattern in the game.
    """

    defstruct [:id, :name, :description, :category, :cells]

    @type t :: %__MODULE__{
            id: atom(),
            name: String.t(),
            description: String.t(),
            category: atom(),
            cells: MapSet.t({integer(), integer()})
          }
  end

  # Patterns listed in the preview section (Life Lexicon)
  @preview_pattern_ids [
    :tower,
    :glider,
    :block,
    :beehive,
    :loaf,
    :blinker,
    :toad,
    :beacon,
    :acorn,
    :puffer,
    :r_pentomino,
    :glider_gun
  ]

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
    case get_pattern_by_id(pattern) do
      %{cells: cells} ->
        cells

      nil ->
        with {:ok, atom} <- safe_to_atom(pattern),
             true <- function_exported?(__MODULE__, atom, 0) do
          apply(__MODULE__, atom, [])
        else
          _ -> random(grid_size)
        end
    end
  end

  @doc """
  Get pattern metadata by ID.
  """
  @spec get_pattern_by_id(atom() | binary()) :: Pattern.t() | nil
  def get_pattern_by_id(id) when is_atom(id) do
    Enum.find(all_patterns(), &(&1.id == id))
  end

  def get_pattern_by_id(id) when is_binary(id) do
    with {:ok, atom_id} <- safe_to_atom(id) do
      get_pattern_by_id(atom_id)
    else
      _ -> nil
    end
  end

  @doc """
  Get all patterns that should be shown in the preview.
  """
  @spec get_preview_patterns() :: [Pattern.t()]
  def get_preview_patterns do
    Enum.filter(all_patterns(), fn pattern -> pattern.id in @preview_pattern_ids end)
  end

  @doc """
  Get all patterns with metadata.
  """
  @spec all_patterns() :: [Pattern.t()]
  def all_patterns do
    [
      %Pattern{
        id: :glider,
        name: "Glider",
        description: "一個會沿對角線移動的圖案，是已知體積最小的太空船。",
        category: :spaceships,
        cells: glider()
      },
      %Pattern{
        id: :block,
        name: "Block",
        description: "最簡單的靜態生命形式。",
        category: :still_lifes,
        cells: block()
      },
      %Pattern{
        id: :beehive,
        name: "Beehive",
        description: "常見的六格靜態生命形式。",
        category: :still_lifes,
        cells: beehive()
      },
      %Pattern{
        id: :loaf,
        name: "Loaf",
        description: "一種七格靜態生命形式。",
        category: :still_lifes,
        cells: loaf()
      },
      %Pattern{
        id: :blinker,
        name: "Blinker",
        description: "最小的週期為 2 的震盪器。",
        category: :oscillators,
        cells: blinker()
      },
      %Pattern{
        id: :toad,
        name: "Toad",
        description: "週期為 2 的六格震盪器。",
        category: :oscillators,
        cells: toad()
      },
      %Pattern{
        id: :beacon,
        name: "Beacon",
        description: "週期為 2 的八格震盪器。",
        category: :oscillators,
        cells: beacon()
      },
      %Pattern{
        id: :acorn,
        name: "Acorn",
        description: "一種會產生高度複雜演化的圖案。",
        category: :methuselahs,
        cells: acorn()
      },
      %Pattern{
        id: :puffer,
        name: "Puffer",
        description: "一種會在移動時留下痕跡的圖案。",
        category: :puffers,
        cells: puffer()
      },
      %Pattern{
        id: :r_pentomino,
        name: "R-pentomino",
        description: "一個會產生複雜演化的五格圖案。",
        category: :methuselahs,
        cells: r_pentomino()
      },
      %Pattern{
        id: :glider_gun,
        name: "Gosper Glider Gun",
        description: "會持續產生滑翔機的圖案。",
        category: :guns,
        cells: glider_gun()
      },
      %Pattern{
        id: :tower,
        name: "Tower",
        description: "我意外發現的長壽圖案，演化 1000 代後仍然存在。",
        category: :methuselahs,
        cells: tower()
      }
    ]
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

  @doc """
  將 RLE (Run Length Encoded) 格式的字串轉換為 MapSet 座標

  RLE 是生命遊戲中常用的模式編碼格式，例如：
  - `bo$2bo$3o!` 表示一個 glider
  - `b` 代表死細胞
  - `o` 代表活細胞
  - `$` 代表換行
  - 數字表示重複次數
  - `!` 表示結束

  ## 參數
  - rle: RLE 格式的字串

  ## 返回
  - MapSet 格式的座標集合

  ## 範例
      iex> rle_to_cells("bo$2bo$3o!")
      #MapSet<[{0, 2}, {1, 0}, {1, 2}, {2, 1}, {2, 2}]>
  """
  @spec rle_to_cells(String.t()) :: MapSet.t()
  def rle_to_cells(rle) do
    # 移除所有空白字符
    rle = String.replace(rle, ~r/\s+/, "")

    # 解析 RLE 字串
    {cells, _} = parse_rle(rle, 0, 0, MapSet.new())
    cells
  end

  # 解析 RLE 字串的遞迴函數
  defp parse_rle("", _, _, cells), do: {cells, ""}
  defp parse_rle("!" <> _, _, _, cells), do: {cells, ""}

  defp parse_rle(rle, x, y, cells) do
    # 嘗試匹配數字（重複次數）
    case Regex.run(~r/^(\d+)(.*)$/, rle) do
      [_, count_str, rest] ->
        # 找到數字，解析為重複次數
        count = String.to_integer(count_str)
        parse_rle_with_count(rest, count, x, y, cells)

      nil ->
        # 沒有數字，處理單個字符
        <<char::utf8, rest::binary>> = rle
        parse_rle_char(char, rest, x, y, cells)
    end
  end

  # 處理帶有重複次數的 RLE
  defp parse_rle_with_count(<<char::utf8, rest::binary>>, count, x, y, cells) do
    case char do
      ?b ->
        # 死細胞，只移動 x 座標
        parse_rle(rest, x + count, y, cells)

      ?o ->
        # 活細胞，添加到 cells 並移動 x 座標
        new_cells =
          Enum.reduce(0..(count - 1), cells, fn i, acc ->
            MapSet.put(acc, {x + i, y})
          end)

        parse_rle(rest, x + count, y, new_cells)

      ?$ ->
        # 換行，重置 x 座標並增加 y 座標
        parse_rle(rest, 0, y + count, cells)

      _ ->
        # 未知字符，忽略
        parse_rle(rest, x, y, cells)
    end
  end

  # 處理單個字符的 RLE
  defp parse_rle_char(char, rest, x, y, cells) do
    case char do
      ?b ->
        # 死細胞，只移動 x 座標
        parse_rle(rest, x + 1, y, cells)

      ?o ->
        # 活細胞，添加到 cells 並移動 x 座標
        parse_rle(rest, x + 1, y, MapSet.put(cells, {x, y}))

      ?$ ->
        # 換行，重置 x 座標並增加 y 座標
        parse_rle(rest, 0, y + 1, cells)

      _ ->
        # 未知字符，忽略
        parse_rle(rest, x, y, cells)
    end
  end
end
