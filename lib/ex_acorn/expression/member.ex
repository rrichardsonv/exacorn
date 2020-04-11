defmodule ExAcorn.Expression.Member do
  import NimbleParsec
  import ExAcorn.Utils
  import ExAcorn.Common

  def member_expression(expr \\ empty()) do
    object = line_text() |> unwrap_and_tag(:object)

    property =
      choice([
        ignore(period()) |> concat(line_text()) |> wrap(),
        bracket_group([expr]) |> unwrap_and_tag(:computed)
      ])
      |> unwrap_and_tag(:property)

    choice([
      object |> concat(property) |> tag(:member_expression),
      ignore(period())
      |> concat(line_text())
      |> tag(:property)
      |> tag(:orphaned_member_expression)
    ])
  end
end
