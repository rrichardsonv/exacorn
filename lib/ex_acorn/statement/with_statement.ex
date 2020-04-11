defmodule ExAcorn.Statement.WithStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def with_statement(expression \\ empty(), root_statement \\ empty()) do
    condition =
      paren_group([expression])
      |> unwrap_and_tag(:condition)

    ignore(string("with"))
    |> optional(space_chars())
    |> concat(condition)
    |> optional(space_chars())
    |> concat(root_statement)
    |> tag(:with_statement)
  end
end
