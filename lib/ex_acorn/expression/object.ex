defmodule ExAcorn.Expression.Object do
  import NimbleParsec
  import ExAcorn.Utils

  def object_expression(expr \\ empty()) do
    key = line_text() |> tag(:key)

    value =
      choice([
        expr,
        line_text() |> unwrap_and_tag(:name) |> tag(:identifier)
      ])
      |> tag(:value)

    property =
      optional(whitespace())
      |> concat(key)
      |> optional(whitespace())
      |> ignore(colon())
      |> optional(whitespace())
      |> concat(value)
      |> optional(space_chars())
      |> optional(comma())
      |> tag(:property)

    ignore(open_curly())
    |> repeat(
      lookahead_not(close_curly())
      |> concat(property)
    )
    |> wrap()
    |> tag(:properties)
    |> optional(whitespace())
    |> ignore(close_curly())
    |> optional(expression_boundary())
    |> tag(:object_expression)
  end
end
