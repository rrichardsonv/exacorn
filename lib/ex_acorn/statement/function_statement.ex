defmodule ExAcorn.Statement.FunctionStatement do
  import NimbleParsec
  import ExAcorn.Common
  import ExAcorn.Utils

  def function_statement(root_statement \\ empty()) do
    gather_op = string("...") |> lookahead(line_text()) |> label("gather")
    async_decorator = string("async") |> concat(whitespace()) |> label("async")

    param =
      choice([
        optional(gather_op) |> concat(line_text()) |> ignore(comma()) |> optional(whitespace()),
        ascii_string([0..255, {:not, ?)}], min: 1)
      ])

    fn_params = paren_group([param]) |> tag(:params)
    fn_name = line_text() |> tag(:name)

    fn_declaration =
      space_chars()
      |> concat(fn_name)
      |> optional(space_chars())
      |> concat(fn_params)
      |> optional(space_chars())
      |> concat(local_block(root_statement))

    choice([
      ignore(async_decorator)
      |> ignore(string("function*"))
      |> concat(fn_declaration)
      |> tag(:async_generator),
      ignore(async_decorator)
      |> ignore(string("function"))
      |> concat(fn_declaration)
      |> tag(:async_function),
      ignore(string("function*"))
      |> concat(fn_declaration)
      |> tag(:generator),
      ignore(string("function"))
      |> concat(fn_declaration)
      |> tag(:function)
    ])
    |> tag(:function_statement)
  end
end
