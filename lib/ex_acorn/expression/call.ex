defmodule ExAcorn.Expression.Call do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def call_expression(expr \\ empty()) do
    args =
      paren_group([
        ignore(comma()) |> concat(expr),
        expr
      ])
      |> unwrap_and_tag(:arguments)

    args |> tag(:call_expression)
  end
end
