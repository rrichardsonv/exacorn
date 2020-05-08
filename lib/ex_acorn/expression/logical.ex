defmodule ExAcorn.Expression.Logical do
  import NimbleParsec
  import ExAcorn.Utils

  def dangling_logical(expr \\ empty()) do
    operator =
      choice([
        string("&&"),
        string("||")
      ])
      |> unwrap_and_tag(:operator)

    meta = empty() |> tag(:meta) |> reduce({__MODULE__, :put_meta, []})

    optional(space_chars())
    |> concat(operator)
    |> optional(whitespace())
    |> concat(meta)
    |> concat(expr |> tag(:right))
    |> tag(:logical_expression)
    |> post_traverse({ExAcorn.Conflict, :tag_precedence, []})
  end

  def put_meta([meta: []]), do: {:meta, :left}
end
