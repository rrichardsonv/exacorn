defmodule ExAcorn.Statement.IfStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def if_statement(expression \\ empty(), root_statement \\ empty()) do
    test =
      paren_group([expression])
      |> unwrap_and_tag(:test)

    alternate_clause =
      choice([
        ignore(string("else"))
        |> optional(whitespace())
        |> concat(curly_group([root_statement]))
        |> tag(:alternate),
        empty() |> tag(:alternate)
      ])

    ignore(string("if"))
    |> optional(whitespace())
    |> concat(test)
    |> optional(whitespace())
    |> choice([
      curly_group([root_statement]) |> tag(:consequent) |> concat(alternate_clause),
      root_statement |> tag(:consequent) |> concat(empty() |> tag(:alternate))
    ])
    |> optional(whitespace())
    |> tag(:if_statement)
  end
end
