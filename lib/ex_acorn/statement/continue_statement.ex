defmodule ExAcorn.Statement.ContinueStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def continue_statement do
    ignore(string("continue"))
    |> optional(space_chars())
    |> optional(quoted_string())
    |> optional(space_chars())
    |> optional(line_text())
    |> optional(space_chars())
    |> concat(expression_boundary())
    |> tag(:continue_statement)
  end
end
