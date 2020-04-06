defmodule ExAcorn.Statement do
  import NimbleParsec
  import ExAcorn.Utils
  import ExAcorn.Common
  import ExAcorn.Statement.SwitchStatement

  line_text =
    ascii_char([?$, ?_, ?a..?z, ?A..?Z])
    |> optional(ascii_string([?$, ?_, ?a..?z, ?A..?Z, ?0..?9], min: 1))
    |> reduce({:line_text_to_string, []})
    |> label("line_text")

  maybe_namespaced_line_text =
    repeat(lookahead_not(whitespace()) |> concat(line_text) |> optional(ignore(ascii_char([?.]))))

  async_decorator = string("async") |> concat(whitespace()) |> label("async")

  defcombinatorp(
    :if_statement,
    ignore(string("if"))
    |> optional(whitespace())
    |> concat(parsec(:test))
    |> optional(whitespace())
    |> concat(parsec(:statement) |> tag(:consequent))
    |> optional(whitespace())
    |> choice([
      ignore(string("else")) |> optional(whitespace()) |> parsec(:statement) |> tag(:alternate),
      empty() |> tag(:alternate)
    ])
    |> tag(:if_statement)
  )

  if_statement = parsec(:if_statement)

  defcombinatorp(
    :else_statement,
    choice([
      ignore(string("else")) |> optional(whitespace()) |> parsec(:statement) |> tag(:alternate),
      empty() |> tag(:alternate)
    ])
  )

  maybe_label_identifier = optional(space_chars() |> concat(line_text)) |> optional(space_chars())
  end_of_statement = choice([ignore(eol()), ignore(semi())]) |> optional(eol())

  # break
  defcombinatorp(
    :break_statement,
    ignore(string("break"))
    |> concat(maybe_label_identifier)
    |> concat(end_of_statement)
    |> tag(:break_statement)
  )

  break_statement = parsec(:break_statement)

  # continue
  defcombinatorp(
    :continue_statement,
    ignore(string("continue"))
    |> concat(maybe_label_identifier)
    |> concat(end_of_statement)
    |> tag(:continue_statement)
  )

  continue_statement = parsec(:continue_statement)

  # with
  defcombinatorp(
    :with_statement,
    ignore(string("with"))
    |> optional(space_chars())
    |> concat(parsec(:condition))
    |> optional(space_chars())
    |> concat(parsec(:block))
    |> tag(:with_statement)
  )

  with_statement = parsec(:with_statement)

  # return
  defcombinatorp(:return_statement, string("return") |> tag(:return_statement))
  # throw
  defcombinatorp(:throw_statement, string("throw") |> tag(:throw_statment))
  throw_statement = parsec(:throw_statement)
  # try
  defcombinatorp(
    :try_statement,
    ignore(string("try"))
    |> optional(space_chars())
    |> concat(parsec(:block))
    |> ignore(whitespace())
    |> parsec(:catch_clause)
    |> tag(:try_statement)
  )

  try_statement = parsec(:try_statement)

  defcombinatorp(
    :catch_clause,
    string("catch")
    |> optional(space_chars())
    |> concat(parsec(:expression))
    |> optional(space_chars())
    |> parsec(:block)
    |> tag(:catch_clause)
  )

  # while
  while_clause =
    ignore(string("while"))
    |> optional(space_chars())
    |> concat(parsec(:condition))

  defcombinatorp(
    :while_statement,
    while_clause
    |> optional(space_chars())
    |> concat(parsec(:block))
    |> tag(:while_statement)
  )

  while_statement = parsec(:while_statement)

  # do
  defcombinatorp(
    :do_statement,
    ignore(string("do"))
    |> optional(whitespace())
    |> concat(parsec(:block))
    |> optional(whitespace())
    |> concat(while_clause)
    |> tag(:do_statement)
  )

  do_statement = parsec(:do_statement)

  # for, for..in, for..of
  defcombinatorp(
    :for_statement,
    ignore(string("for"))
    |> optional(space_chars())
    |> concat(parsec(:expression))
    |> optional(space_chars())
    |> concat(parsec(:block))
    |> tag(:for_statement)
  )

  for_statement = parsec(:for_statement)

  # debugger
  debugger_statement = string("debugger") |> tag(:debugger_statement)

  # [async] function, function*

  defcombinatorp(
    :_block,
    ignore(open_curly())
    |> repeat(
      lookahead_not(close_curly())
      |> choice([
        optional(whitespace()) |> concat(comment()),
        optional(whitespace()) |> concat(quoted_string()),
        optional(whitespace()) |> parsec(:if_statement),
        optional(whitespace()) |> parsec(:try_statement),
        optional(whitespace()) |> parsec(:for_statement),
        optional(whitespace()) |> concat(switch_statement()),
        optional(whitespace()) |> parsec(:function_statement),
        optional(whitespace()) |> parsec(:anonymous_function),
        optional(whitespace()) |> concat(variable_statement()),
        optional(whitespace()) |> parsec(:return_statement),
        optional(whitespace()) |> parsec(:throw_statement),
        optional(whitespace()) |> parsec(:break_statement),
        optional(whitespace()) |> parsec(:continue_statement),
        optional(whitespace()) |> parsec(:function_call),
        optional(whitespace()) |> parsec(:label_statement),
        parsec(:block_statement),
        ignore(whitespace()),
        optional(whitespace()) |> concat(non_control_char()),
        optional(whitespace()) |> concat(comma()),
        optional(whitespace()) |> concat(semi()),
        optional(whitespace()) |> concat(period()),
        optional(whitespace()) |> concat(open_paren()),
        optional(whitespace()) |> concat(close_paren()),
        optional(whitespace()) |> concat(colon()),
        optional(whitespace()) |> concat(eq()),
        optional(whitespace()) |> concat(question_mark())
      ])
    )
    |> wrap()
    |> optional(whitespace())
    |> ignore(close_curly())
  )

  defcombinatorp(:block, parsec(:_block) |> unwrap_and_tag(:block))
  defcombinatorp(:block_statement, parsec(:_block) |> unwrap_and_tag(:block_statement))

  defcombinatorp(
    :paren_group,
    ignore(open_paren())
    |> repeat(
      lookahead_not(close_paren())
      |> choice([
        optional(whitespace()) |> concat(comment()),
        optional(whitespace()) |> concat(quoted_string()),
        optional(whitespace()) |> concat(variable_statement()) |> optional(eq()),
        parsec(:expression),
        ascii_string([not: ?(, not: ?)], min: 1)
      ])
    )
    |> wrap()
    |> optional(whitespace())
    |> ignore(close_paren())
  )

  defcombinatorp(:expression, parsec(:paren_group) |> unwrap_and_tag(:expression))
  defcombinatorp(:condition, parsec(:paren_group) |> unwrap_and_tag(:condition))
  defcombinatorp(:discriminant, parsec(:paren_group) |> unwrap_and_tag(:discriminant))
  defcombinatorp(:test, parsec(:paren_group) |> unwrap_and_tag(:test))

  gather_op = string("...") |> label("gather")

  param =
    choice([
      optional(gather_op) |> concat(line_text) |> ignore(comma()) |> optional(whitespace()),
      ascii_string([0..255, {:not, ?)}], min: 1)
    ])

  fn_params =
    ignore(open_paren())
    |> repeat(lookahead_not(close_paren()) |> concat(param))
    |> ignore(close_paren())
    |> tag(:params)

  fn_name =
    line_text
    |> tag(:fn_name)

  fn_declaration =
    fn_name
    |> optional(space_chars())
    |> concat(fn_params)
    |> optional(space_chars())
    |> concat(parsec(:block))

  defcombinatorp(
    :function_statement,
    optional(async_decorator)
    |> choice([
      string("function*") |> label("generator kw"),
      string("function") |> label("function kw")
    ])
    |> concat(space_chars())
    |> concat(fn_declaration)
    |> tag(:function_statement)
  )

  defcombinatorp(
    :anonymous_function,
    string("function")
    |> label("function kw")
    |> concat(space_chars())
    |> concat(fn_params)
    |> optional(space_chars())
    |> concat(parsec(:block))
    |> tag(:anonymous_function)
  )

  function_statement = parsec(:function_statement)

  defcombinatorp(
    :function_call,
    fn_name
    |> concat(parsec(:expression))
    |> tag(:function_call)
  )

  # method_call = ignore(ascii_char([?.])) |> parsec(:function_call)

  # class
  extends_clause =
    ignore(string("extends"))
    |> concat(whitespace())
    |> concat(maybe_namespaced_line_text |> tag(:extends))

  defcombinatorp(
    :class_statement,
    ignore(string("class"))
    |> concat(whitespace())
    |> concat(maybe_namespaced_line_text |> tag(:classname))
    |> optional(whitespace() |> concat(extends_clause))
    |> optional(whitespace())
    |> parsec(:block)
    |> tag(:class_statement)
  )

  class_statement = parsec(:class_statement)
  # export
  defcombinatorp(
    :export_statement,
    ignore(string("export"))
    |> optional(whitespace() |> concat(string("default")))
    |> concat(whitespace())
    |> choice([
      variable_statement(),
      function_statement,
      class_statement,
      whitespace(),
      non_control_char()
    ])
    |> tag(:export_statement)
  )

  export_statement = parsec(:export_statement)
  # import.meta
  import_meta_statement = string("import.meta") |> tag(:import_meta_statement)
  # import
  import_statement = string("import") |> tag(:import_statement)
  # label:

  defcombinatorp(
    :label_statement,
    optional(space_chars())
    |> concat(line_text)
    |> optional(space_chars())
    |> ignore(colon())
    |> optional(whitespace())
    |> tag(:label_statement)
  )

  defcombinatorp(
    :statement,
    optional(whitespace())
    |> choice([
      if_statement,
      break_statement,
      continue_statement,
      with_statement,
      switch_statement(),
      parsec(:return_statement),
      throw_statement,
      try_statement,
      while_statement,
      do_statement,
      for_statement,
      parsec(:label_statement),
      debugger_statement,
      parsec(:block_statement)
    ])
    |> label("statement")
  )

  root =
    choice([
      comment(),
      quoted_string(),
      if_statement,
      break_statement,
      continue_statement,
      with_statement,
      switch_statement(),
      parsec(:return_statement),
      throw_statement,
      try_statement,
      while_statement,
      do_statement,
      for_statement,
      parsec(:label_statement),
      debugger_statement,
      variable_statement(),
      function_statement,
      class_statement,
      export_statement,
      import_meta_statement,
      import_statement,
      whitespace(),
      non_control_char(),
      comma(),
      semi(),
      period(),
      close_brace(),
      open_brace(),
      colon(),
      question_mark(),
      open_paren(),
      close_paren(),
      eq()
    ])

  defparsec(
    :parse,
    optional(whitespace())
    |> repeat(lookahead_not(eos()) |> concat(root))
    |> eos()
  )

  defp line_text_to_string([char | _] = line_text) when is_integer(char),
    do: List.to_string(line_text)

  defp line_text_to_string([char, rest]) when is_integer(char), do: List.to_string([char]) <> rest
end
