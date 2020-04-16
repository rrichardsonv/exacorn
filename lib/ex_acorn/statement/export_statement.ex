defmodule ExAcorn.Statement.ExportStatement do
  import NimbleParsec
  import ExAcorn.Utils

  def export_statement(decl_comb \\ [empty()]) do
    default_spec = string("default") |> tag(:specifier)
    # named_specifier =
    #   repeat(lookahead_not(string(" from ") |> concat(ascii_string([]))))

    ignore(string("export"))
    |> concat(whitespace())
    |> choice([
      default_spec
      |> concat(whitespace())
      |> choice(decl_comb ++ [whitespace()]),
      whitespace()
      |> choice(decl_comb ++ [whitespace()])
      |> tag(:literal)
    ])
    |> tag(:export_statement)
  end
end
