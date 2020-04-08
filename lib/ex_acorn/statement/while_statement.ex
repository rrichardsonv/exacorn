defmodule ExAcorn.Statement.WhileStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def while_statement(root_statement \\ empty()) do
    condition =
      paren_group([
        optional(whitespace()) |> concat(comment()),
        optional(whitespace()) |> concat(quoted_string()),
        variable_statement(),
        ascii_string([not: ?(, not: ?)], min: 1)
      ])
      |> tag(:condition)

    ignore(string("while"))
    |> optional(space_chars())
    |> concat(condition)
    |> optional(space_chars())
    |> concat(local_block(root_statement) |> tag(:block))
    |> tag(:while_statement)
  end

  def do_statement(root_statement \\ empty()) do
    condition =
      paren_group([
        optional(whitespace()) |> concat(comment()),
        optional(whitespace()) |> concat(quoted_string()),
        variable_statement(),
        ascii_string([not: ?(, not: ?)], min: 1)
      ])
      |> unwrap_and_tag(:condition)

    ignore(string("do"))
    |> optional(whitespace())
    |> concat(local_block(root_statement) |> tag(:block))
    |> optional(whitespace())
    |> ignore(string("while"))
    |> optional(space_chars())
    |> concat(condition)
    |> tag(:do_statement)
  end
end
