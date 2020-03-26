defmodule ExAcornTest do
  use ExUnit.Case

  alias ESTree.Program
  alias ESTree.SourceLocation
  alias ESTree.Position
  alias ESTree.EmptyStatement

  describe "parse/1" do
    test "produces a program with source location" do
      expected_output = %Program{
        loc: %SourceLocation{
          source: "",
          end: %Position{column: 0, line: 1},
          start: %Position{column: 0, line: 1}
        }
      }

      assert_output("", expected_output)
    end

    test "can parse an empty statment" do
      expected_source_location = %SourceLocation{
        source: ";",
        start: %Position{column: 0, line: 1},
        end: %Position{column: 1, line: 1}
      }

      expected_output = %Program{
        body: [
          %EmptyStatement{
            loc: expected_source_location
          }
        ],
        loc: expected_source_location
      }

      assert_output_matches(";", expected_output)
    end

    test "can parse an empty statment with newlines and whitespace" do
      expected_source_location = %SourceLocation{
        source: ";",
        start: %Position{column: 0, line: 1},
        end: %Position{column: 6, line: 4}
      }

      expected_output = %Program{
        body: [
          %EmptyStatement{
            loc: expected_source_location
          }
        ],
        loc: expected_source_location
      }

      assert_output_matches("\n\n ;\n", expected_output)
    end

    defp assert_output(input, output) do
      parsed = ExAcorn.parse(input)

      assert output == parsed, """
      Expected parsed:
        #{inspect(parsed, pretty: true)}
      to match...
        #{inspect(output, pretty: true)}
      """
    end

    defp assert_output_matches(input, output) do
      parsed = ExAcorn.parse(input)

      assert match?(^output, parsed), """
      Expected parsed:
        #{inspect(parsed, pretty: true)}
      to match...
        #{inspect(output, pretty: true)}
      """
    end
  end
end
