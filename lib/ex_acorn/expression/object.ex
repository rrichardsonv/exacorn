defmodule ExAcorn.Expression.Object do
  import NimbleParsec
  import ExAcorn.Utils

  def object_expression(expr \\ empty()) do
    key = line_text() |> tag(:key)

    value = colon() |> concat(expr |> tag(:value))

    property =
      optional(whitespace())
      |> concat(key)
      |> optional(whitespace())
      |> concat(value)
      |> optional(whitespace())
      |> optional(comma())
      |> tag(:property)

    ignore(open_curly())
    |> repeat(
      lookahead_not(close_curly())
      |> optional(whitespace())
      |> concat(property)
    )
    |> wrap()
    |> tag(:properties)
    |> optional(whitespace())
    |> ignore(close_curly())
    |> concat(expression_boundary())
    |> tag(:object_expression)
  end
end
