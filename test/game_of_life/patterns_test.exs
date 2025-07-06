defmodule GameOfLife.PatternsTest do
  use ExUnit.Case
  alias GameOfLife.Patterns

  describe "rle_to_cells/1" do
    test "parse valid RLE format" do
      assert Patterns.rle_to_cells("bo$2bo$3o!") ==
               MapSet.new([{1, 0}, {2, 1}, {0, 2}, {1, 2}, {2, 2}])

      assert Patterns.rle_to_cells("2o$2o!") ==
               MapSet.new([{0, 0}, {1, 0}, {0, 1}, {1, 1}])
    end

    test "handle whitespace" do
      assert Patterns.rle_to_cells("bo $2bo $3o!") ==
               MapSet.new([{1, 0}, {2, 1}, {0, 2}, {1, 2}, {2, 2}])

      assert Patterns.rle_to_cells("bo\n$2bo\n$3o!") ==
               MapSet.new([{1, 0}, {2, 1}, {0, 2}, {1, 2}, {2, 2}])
    end

    test "handle incomplete RLE (missing end marker)" do
      assert Patterns.rle_to_cells("bo$2bo$3o") ==
               MapSet.new([{1, 0}, {2, 1}, {0, 2}, {1, 2}, {2, 2}])
    end

    test "handle invalid RLE format - invalid character" do
      # 包含無效字元 x 的 RLE
      assert_raise ArgumentError, fn ->
        Patterns.rle_to_cells("xo$2bo$3o!")
      end
    end

    test "handle invalid RLE format - non-numeric character as count" do
      assert_raise ArgumentError, fn ->
        Patterns.rle_to_cells("bo$abo$3o!")
      end
    end

    test "handle empty string" do
      assert Patterns.rle_to_cells("") == MapSet.new([])
    end

    test "handle RLE with only end marker" do
      assert Patterns.rle_to_cells("!") == MapSet.new([])
    end
  end
end
