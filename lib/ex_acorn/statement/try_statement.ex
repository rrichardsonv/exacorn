defmodule ExAcorn.Statement.TryStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def try_statement(root_statement \\ empty()) do
    expression =
      paren_group([
        optional(whitespace()) |> concat(comment()),
        optional(whitespace()) |> concat(quoted_string()),
        variable_statement(),
        ascii_string([not: ?(, not: ?)], min: 1)
      ])
      |> unwrap_and_tag(:expression)

    catch_clause =
      ignore(string("catch"))
      |> optional(space_chars())
      |> concat(expression)
      |> optional(space_chars())
      |> concat(local_block(root_statement))
      |> tag(:catch_clause)

    ignore(string("try"))
    |> optional(space_chars())
    |> concat(local_block(root_statement))
    |> ignore(whitespace())
    |> concat(catch_clause)
    |> tag(:try_statement)
  end
end
