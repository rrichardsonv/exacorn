defmodule ExAcorn.Statement.BreakStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def break_statement do
    ignore(string("break"))
    |> optional(space_chars())
    |> optional(quoted_string())
    |> optional(space_chars())
    |> optional(line_text())
    |> optional(space_chars())
    |> concat(expression_boundary())
    |> tag(:break_statement)
  end
end
