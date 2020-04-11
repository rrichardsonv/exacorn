defmodule ExAcorn.Statement.ForStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def for_statement(expression \\ empty(), root_statement \\ empty()) do
    condition =
      paren_group([expression])
      |> unwrap_and_tag(:condition)

    ignore(string("for"))
    |> optional(space_chars())
    |> concat(condition)
    |> optional(space_chars())
    |> concat(root_statement)
    |> tag(:for_statement)
  end
end
