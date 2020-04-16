defmodule ExAcorn.Expression.Function do
  import NimbleParsec
  import ExAcorn.Utils
  import ExAcorn.Common

  def function_expression(expr \\ empty(), root_combinator \\ empty()) do
    gather_op = string("...") |> lookahead(line_text()) |> label("gather")

    param =
      choice([
        optional(gather_op)
        |> concat(line_text())
        |> optional(whitespace())
        |> lookahead_not(comma()),
        ascii_string([0..255, {:not, ?)}], min: 1)
      ])

    fn_params =
      choice([
        ignore(string("function"))
        |> optional(space_chars())
        |> concat(paren_group([param]))
        |> unwrap_and_tag(:params),
        paren_group([param])
        |> unwrap_and_tag(:params)
        |> optional(space_chars())
        |> ignore(string("=>"))
      ])

    single_arg_shorthand =
      choice([
        line_text(),
        ignore(open_paren()) |> ignore(close_paren())
      ])
      |> tag(:param)
      |> optional(space_chars())
      |> ignore(string("=>"))
      |> concat(empty() |> tag(:id))
      |> optional(space_chars())

    choice([
      fn_params
      |> optional(space_chars())
      |> concat(empty() |> tag(:id))
      |> concat(root_combinator |> tag(:body)),
      single_arg_shorthand
      |> choice([
        expr
        |> tag(:argument)
        |> tag(:return_statement)
        |> tag(:body),
        root_combinator |> tag(:body)
      ])
    ])
    |> optional(expression_boundary())
    |> tag(:function_expression)
  end
end
