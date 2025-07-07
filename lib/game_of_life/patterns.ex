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
    :phoenix,
    :p24_gun,
    :p60_gun,
    :rats,
    :tower,
    :glider,
    :block,
    :beehive

    # WIP：測試畫面中，暫時註解掉其他 id
    # :loaf,
    # :blinker,
    # :toad,
    # :beacon,
    # :acorn,
    # :puffer,
    # :r_pentomino,
    # :glider_gun
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
        id: :phoenix,
        name: "Phoenix",
        description:
          ~S'Any pattern all of whose cells die in every generation, but which never dies as a whole. A spaceship cannot be a phoenix, and in fact every finite phoenix eventually evolves into an oscillator. The following 12-cell oscillator (found by the MIT group in December 1971) is the smallest known phoenix, and is sometimes called simply "the phoenix".',
        category: :oscillators,
        cells: rle_to_cells("4bo3b$2bobo$6bo$2o$6b2o$bo$3bobo$3bo!")
      },
      %Pattern{
        id: :p24_gun,
        name: "p24 gun",
        description:
          "A true period 24 glider gun that was found by Noam Elkies in 1997 (originally with two different fountains in place of the superfountains used use here). In the form displayed here, it has period 48 due to the filter being used to double the period of the output stream. Remove that bottom-most oscillator to recover the p24 gun.",
        category: :glider_guns,
        cells:
          rle_to_cells("26bo2bo$24b6o$20b2obo8bo$16b2obobobob8o2bo$14b3ob2o3bobo7b3o$13bo6bo2b
o3b2ob3o$14b4o3bob4o5bob2o$15bo5bo5bo5bobo$13bo3bo4bob2o2bo4b2o7bo$13b
4o2b4obo4b2o2bo7b2o$18b2o4bo6b3o8bo5bo$15b3o3b3o5bo8bob2o4b2obo$14bo5b
2o5bob2o7bo3bob4o2bo$9bo5b3o8b2obob3o3bob2o3bobo4bo$9b3o5b2ob2o9b3o6bo
3bobob3o$3bo18bo5b2o2b2o4bo2bo3bobo$2bobo5b4o4bo6bobo9bo3bo5bob2o$bob
2ob2obo2b2o5bob2o3bo11bo2bo4b2o2bo$o2bo3bob2o27bo4b2o3b2o$b3obobob2o2b
2o15bo3bo3bo6b3o$4bobobobo17b2o8bo4b2o3b2o$b2obo3b2o3bobo14bo7bo2bo4b
2o2bo$bo2b2o2b2o2bo2bo5bobo13bo3bo5bob2o$2b2o3b2obo3b3o3bo2bo14bo2bo3b
obo$4b3o7b3o4bobo3bo12bo3bobob3o$2b2o3b2obo3b3o11b2o7bob2o3bobo4bo$bo
2b2o2b2o2bo2bo11b2o9bo3bob4o2bo$b2obo3b2o3bobo22bob2o4b2obo$4bobobobo
13b2o16bo5bo$b3obobob2o2b2o9bo16b2o$o2bo3bob2o14b3o5bo8bo$bob2ob2obo2b
2o13bo6b2o$2bobo5b4o19b2o$3bo$9b3o$9bo15bo3bo$24bobobobo8bo$23bo2bobo
2bo8b2o$22b2ob2ob2ob2o6b2o$21bo3bo3bo3bo$20bo2bob2ob2obo2bo$23bo7bo$
25b2ob2o$20bo5bobo5bo$21b2ob2o3b2ob2o4$51bo$52b2o$51b2o10$63bo$64b2o$
63b2o!")
      },
      %Pattern{
        id: :p60_gun,
        name: "p60 gun",
        description: "A period 60 gun constructed from two Gosper glider guns.",
        category: :glider_guns,
        cells: rle_to_cells("30bo$29bobo$12b2o15b2obo$12bobo14b2ob2o3b2o$3b2o2b2o6bo13b2obo4b2o$3b
2obo2bo2bo2bo13bobo$7b2o6bo8bo5bo$12bobo7bobo$12b2o9b2o3$25b3o$27bo$
26bo4bo$32bo$30b3o$9bobo$7bo3bo5b3o$2o5bo7bobo2bo2b2o$2o4bo4bo7b2o2bo
2bo$7bo19bo$7bo3bo2b3o10bo$9bobo15bo$23bo2bo6b2o$23b2o8bobo$35bo$35b2o
2$46bo$47bo$45b3o13$61bo$62bo$60b3o!")
      },
      %Pattern{
        id: :rats,
        name: "Rats",
        description:
          "A period 6 oscillator found in 1972. www.conwaylife.com/wiki/index.php?title=$rats",
        category: :oscillators,
        cells:
          rle_to_cells("5b2o5b$6bo5b$4bo7b$2obob4o3b$2obo5bobo$3bo2b3ob2o$3bo4bo3b$4b3obo3b$7b
o4b$6bo5b$6b2o!")
      },
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
    rle_to_cells("b2ob$o2bo$b2ob!")
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
