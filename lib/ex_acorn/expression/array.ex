defmodule ExAcorn.Expression.Array do
  import NimbleParsec
  import ExAcorn.Common

  def array_expression(element_combinator \\ empty())

  def array_expression(combinators) when is_list(combinators) do
    combinators
    |> bracket_group()
    |> unwrap_and_tag(:array_expression)
  end

  def array_expression(element_combinator) do
    element_combinator
    |> List.wrap()
    |> bracket_group()
    |> unwrap_and_tag(:array_expression)
  end
end
