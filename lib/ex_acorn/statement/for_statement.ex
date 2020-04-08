defmodule ExAcorn.Statement.ForStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def for_statement(root_statement \\ empty()) do
    condition =
      paren_group([
        optional(whitespace()) |> concat(comment()),
        optional(whitespace()) |> concat(quoted_string()),
        variable_statement(),
        ascii_string([not: ?(, not: ?)], min: 1)
      ])
      |> tag(:condition)

    ignore(string("for"))
    |> optional(space_chars())
    |> concat(condition)
    |> optional(space_chars())
    |> concat(local_block(root_statement))
    |> tag(:for_statement)
  end
end
