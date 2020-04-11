defmodule ExAcorn.Expression.New do
  import NimbleParsec
  import ExAcorn.Utils
  import ExAcorn.Common

  def new_expression(expression_combinator \\ empty()) do
    arguments =
      paren_group([expression_combinator])
      |> unwrap_and_tag(:arguments)

    ignore(string("new"))
    |> concat(whitespace())
    |> tag(expression_combinator, :callee)
    |> concat(whitespace())
    |> concat(arguments)
    |> concat(expression_boundary())
  end
end
