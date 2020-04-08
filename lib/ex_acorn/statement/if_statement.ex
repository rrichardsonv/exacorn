defmodule ExAcorn.Statement.IfStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def if_statement(root_statement \\ empty()) do
    test =
      paren_group([
        optional(whitespace()) |> concat(comment()),
        optional(whitespace()) |> concat(quoted_string()),
        variable_statement(),
        ascii_string([not: ?(, not: ?)], min: 1)
      ])
      |> unwrap_and_tag(:test)

    ignore(string("if"))
    |> optional(whitespace())
    |> concat(test)
    |> optional(whitespace())
    |> concat(local_block(root_statement) |> tag(:consequent))
    |> optional(whitespace())
    |> choice([
      ignore(string("else"))
      |> optional(whitespace())
      |> concat(local_block(root_statement))
      |> tag(:alternate),
      empty() |> tag(:alternate)
    ])
    |> tag(:if_statement)
  end
end
