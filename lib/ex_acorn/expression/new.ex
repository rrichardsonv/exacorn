defmodule ExAcorn.Expression.New do
  import NimbleParsec
  import ExAcorn.Utils

  def new_expression(expr \\ empty()) do
    callee = expr |> tag(:callee)

    ignore(string("new"))
    |> concat(whitespace())
    |> concat(callee)
    |> tag(:new_expression)
  end
end
