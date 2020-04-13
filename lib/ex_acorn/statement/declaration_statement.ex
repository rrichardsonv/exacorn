defmodule ExAcorn.Statement.DeclarationStatement do
  import NimbleParsec
  import ExAcorn.Utils

  def variable_statement(expression_combinator \\ empty()) do
    declaration =
      choice([
        ignore(eq())
        |> optional(whitespace())
        |> repeat(
          lookahead_not(ascii_char([?\n, ?\r, ?\,, ?\=, ?;]))
          |> concat(expression_combinator)
        )
        |> optional(
          comma()
          |> ignore()
          |> concat(whitespace())
          |> ignore()
        )
        |> tag(:init),
        ignore(comma())
        |> optional(whitespace())
        |> tag(:init)
      ])

    declaration_id =
      line_text()
      |> optional(space_chars())
      |> unwrap_and_tag(:id)

    declarations =
      repeat(
        lookahead_not(expression_boundary())
        |> concat(declaration_id)
        |> optional(space_chars())
        |> optional(declaration)
        |> tag(:variable_declarator)
      )
      |> tag(:declarations)

    choice([string("let"), string("const"), string("var")])
    |> unwrap_and_tag(:kind)
    |> ignore(whitespace())
    |> concat(declarations)
    |> ignore(expression_boundary())
    |> tag(:variable_statement)
  end
end
