defmodule ExAcorn.Expression.Function do
  import NimbleParsec
  import ExAcorn.Utils
  import ExAcorn.Common

  def function_expression(root_combinator \\ empty()) do
    gather_op = string("...") |> lookahead(line_text()) |> label("gather")

    param =
      choice([
        optional(gather_op)
        |> concat(line_text())
        |> optional(whitespace())
        |> lookahead_not(comma()),
        ascii_string([0..255, {:not, ?)}], min: 1)
      ])

    fn_params = paren_group([param]) |> unwrap_and_tag(:params)

    choice([
      ignore(string("function")) |> optional(space_chars()) |> concat(fn_params),
      fn_params |> optional(space_chars()) |> ignore(string("=>")),
      line_text() |> tag(:param) |> ignore(space_chars()) |> ignore(string("=>"))
    ])
    |> optional(space_chars())
    |> concat(empty() |> tag(:id))
    |> concat(root_combinator |> tag(:body))
    |> optional(expression_boundary())
    |> tag(:function_expression)
  end
end
