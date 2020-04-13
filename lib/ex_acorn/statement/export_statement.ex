defmodule ExAcorn.Statement.ExportStatement do
  import NimbleParsec
  import ExAcorn.Utils

  def export_statement(declaration_combinators \\ empty()) do
    default_spec = string("default") |> tag(:specifier)
    # named_specifier =
    #   repeat(lookahead_not(string(" from ") |> concat(ascii_string([]))))

    ignore(string("export"))
    |> concat(whitespace())
    |> choice([
      default_spec
      |> concat(whitespace())
      |> choice(declaration_combinators ++ [whitespace()]),
      whitespace()
      |> choice(declaration_combinators ++ [whitespace()])
      |> tag(:literal)
    ])
    |> tag(:export_statement)
  end
end
