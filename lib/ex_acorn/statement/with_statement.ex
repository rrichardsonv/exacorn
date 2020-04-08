defmodule ExAcorn.Statement.WithStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def with_statement(root_statement \\ empty()) do
    ignore(string("with"))
    |> optional(space_chars())
    |> concat(
      paren_group([
        optional(whitespace()) |> concat(comment()),
        optional(whitespace()) |> concat(quoted_string()),
        variable_statement(),
        ascii_string([not: ?(, not: ?)], min: 1)
      ])
      |> tag(:condition)
    )
    |> optional(space_chars())
    |> concat(local_block(root_statement))
    |> tag(:with_statement)
  end
end
