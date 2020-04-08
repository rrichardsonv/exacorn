defmodule ExAcorn.Expression.Function do
  import NimbleParsec
  import ExAcorn.Utils
  import ExAcorn.Common

  def function_expression(root_combinator \\ empty()) do
    gather_op = string("...") |> lookahead(line_text()) |> label("gather")

    param =
      choice([
        optional(gather_op) |> concat(line_text()) |> ignore(comma()) |> optional(whitespace()),
        ascii_string([0..255, {:not, ?)}], min: 1)
      ])

    fn_params = paren_group([param]) |> tag(:params)

    choice([
      ignore(string("function")) |> optional(space_chars()) |> concat(fn_params),
      fn_params |> optional(space_chars()) |> concat(string("=>"))
    ])
    |> optional(space_chars())
    |> concat(local_block(root_combinator))
    |> optional(expression_boundary())
    |> tag(:function_expression)
  end

  def function_evocation(expression_combinator \\ empty()) do
    line_text()
    |> tag(:fn_name)
    |> concat(paren_group([expression_combinator]))
    |> optional(expression_boundary())
    |> tag(:function_call)
  end
end
