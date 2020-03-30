defmodule ExAcorn.Statement do
  import NimbleParsec

  # utils
  whitespace = ascii_string([?\s, ?\t, ?\n, ?\r], min: 1) |> ignore() |> label("whitespace")
  space_chars = ascii_string([?\s, ?\t, ?\r], min: 1) |> ignore() |> label("space_chars")

  non_whitespace_char =
    ascii_string([not: ?\s, not: ?\t, not: ?\n, not: ?\r], min: 1) |> label("non_whitespace")

  eol = ascii_char([?\n]) |> ignore() |> label("eol")
  semi = ascii_char([?;]) |> tag(:semi)

  open_curly = ascii_char([?{])
  close_curly = ascii_char([?}])

  open_brace = open_curly |> tag(:open_brace)
  close_brace = close_curly |> tag(:close_brace)

  colon = ascii_char([?:]) |> tag(:colon)
  comma = ascii_char([?,]) |> tag(:comma)
  eq = ascii_char([?=]) |> tag(:eq)
  question_mark = ascii_char([??]) |> tag(:question_mark)

  double_quote = ascii_char([?"]) |> ignore() |> label("double_quote")
  single_quote = ascii_char([?']) |> ignore() |> label("single_quote")
  backtick_quote = ascii_char([?`]) |> ignore() |> label("backtick_quote")

  unknown_text =
    ascii_string(
      [
        10..255,
        {:not, ?"},
        {:not, ?'},
        {:not, ?`},
        {:not, ?,},
        {:not, ?;},
        {:not, ?}},
        {:not, ?{},
        {:not, ?(},
        {:not, ?)},
        {:not, ?:},
        {:not, ??}
      ],
      min: 1
    )
    |> tag(:unknown_text)

  defcombinatorp(
    :double_quoted_text,
    double_quote
    |> repeat(lookahead_not(double_quote) |> concat(ascii_string([0..255, {:not, ?"}], min: 1)))
    |> concat(double_quote)
    |> tag(:quoted_string)
  )

  defcombinatorp(
    :single_quoted_text,
    single_quote
    |> repeat(lookahead_not(single_quote) |> concat(ascii_string([0..255, {:not, ?'}], min: 1)))
    |> concat(single_quote)
    |> tag(:quoted_string)
  )

  defcombinatorp(
    :backtick_quoted_text,
    backtick_quote
    |> repeat(lookahead_not(backtick_quote) |> concat(ascii_string([0..255, {:not, ?`}], min: 1)))
    |> concat(backtick_quote)
    |> tag(:quoted_template)
  )

  quoted_string =
    choice([
      parsec(:double_quoted_text),
      parsec(:single_quoted_text),
      parsec(:backtick_quoted_text)
    ])

  inline_comment =
    string("//") |> concat(ascii_string([0..255, {:not, ?\n}], min: 0)) |> lookahead(eol)

  block_comment_content =
    ascii_string([0..255, {:not, ?*}], min: 1)
    |> optional(ascii_char([?*]) |> lookahead_not(ascii_char([?/])))

  block_comment =
    string("/*")
    |> repeat(lookahead_not(string("*/")) |> concat(block_comment_content))
    |> concat(string("*/"))

  defcombinatorp(:comment, choice([inline_comment, block_comment]) |> tag(:comment))

  comment = parsec(:comment)

  line_text =
    ascii_char([?$, ?_, ?a..?z, ?A..?Z])
    |> optional(ascii_string([?$, ?_, ?a..?z, ?A..?Z, ?0..?9], min: 1))
    |> reduce({:line_text_to_string, []})
    |> label("line_text")

  maybe_namespaced_line_text =
    repeat(lookahead_not(whitespace) |> concat(line_text) |> optional(ignore(ascii_char([?.]))))

  open_paren = ascii_char([?(]) |> tag(:open_paren)
  close_paren = ascii_char([?)]) |> tag(:close_paren)

  async_decorator = string("async") |> concat(whitespace) |> label("async")

  defcombinatorp(
    :if_statement,
    ignore(string("if"))
    |> optional(space_chars)
    |> concat(parsec(:condition))
    |> optional(space_chars)
    |> choice([
      parsec(:return_statement)
      |> optional(
        space_chars
        |> concat(ascii_string([not: ?;, not: ?\n], min: 1))
      )
      |> concat(ignore(ascii_char([?;, ?\n]))),
      parsec(:block)
      |> ignore(whitespace)
      |> optional(parsec(:else_statement))
    ])
    |> tag(:if_statement)
  )

  if_statement = parsec(:if_statement)

  defcombinatorp(
    :else_statement,
    ignore(string("else"))
    |> choice([
      ignore(whitespace) |> concat(if_statement),
      optional(whitespace) |> parsec(:block)
    ])
    |> tag(:else_statement)
  )

  maybe_label_identifier = optional(space_chars |> concat(line_text)) |> optional(space_chars)
  end_of_statement = choice([ignore(eol), ignore(semi)])

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
    |> optional(space_chars)
    |> concat(parsec(:condition))
    |> optional(space_chars)
    |> concat(parsec(:block))
    |> tag(:with_statement)
  )

  with_statement = parsec(:with_statement)

  # switch
  defcombinatorp(
    :switch_statement,
    ignore(string("switch"))
    |> optional(space_chars)
    |> concat(parsec(:condition))
    |> optional(space_chars)
    |> concat(parsec(:block))
    |> tag(:switch_statement)
  )

  switch_statement = parsec(:switch_statement)
  # return
  defcombinatorp(:return_statement, string("return") |> tag(:return_statement))
  # throw
  defcombinatorp(:throw_statement, string("throw") |> tag(:throw_statment))
  throw_statement = parsec(:throw_statement)
  # try
  defcombinatorp(
    :try_statement,
    ignore(string("try"))
    |> optional(space_chars)
    |> concat(parsec(:block))
    |> ignore(whitespace)
    |> parsec(:catch_clause)
    |> tag(:try_statement)
  )

  try_statement = parsec(:try_statement)

  defcombinatorp(
    :catch_clause,
    string("catch")
    |> optional(space_chars)
    |> concat(parsec(:expression))
    |> optional(space_chars)
    |> parsec(:block)
    |> tag(:catch_clause)
  )

  # while
  while_clause =
    ignore(string("while"))
    |> optional(space_chars)
    |> concat(parsec(:condition))

  defcombinatorp(
    :while_statement,
    while_clause
    |> optional(space_chars)
    |> concat(parsec(:block))
    |> tag(:while_statement)
  )

  while_statement = parsec(:while_statement)

  # do
  defcombinatorp(
    :do_statement,
    ignore(string("do"))
    |> optional(space_chars)
    |> concat(parsec(:block))
    |> optional(whitespace)
    |> concat(while_clause)
    |> tag(:do_statement)
  )

  do_statement = parsec(:do_statement)

  # for, for..in, for..of
  defcombinatorp(
    :for_statement,
    ignore(string("for"))
    |> optional(space_chars)
    |> concat(parsec(:expression))
    |> optional(space_chars)
    |> concat(parsec(:block))
    |> tag(:for_statement)
  )

  for_statement = parsec(:for_statement)

  # debugger
  debugger_statement = string("debugger") |> tag(:debugger_statement)
  # const, var, let
  multiple_decl_separator = comma |> optional(whitespace)

  var_declare =
    line_text
    |> concat(ascii_string([?\s, ?\t], min: 0) |> ignore() |> label("whitespace"))
    |> repeat(ignore(multiple_decl_separator) |> concat(line_text))

  assigned_var =
    ignore(eq)
    |> optional(whitespace)
    |> lookahead(non_whitespace_char)
    |> tag(:assignment)

  instantiated_var =
    end_of_statement
    |> tag(:no_assign)

  defcombinatorp(
    :variable_statement,
    choice([string("let"), string("const"), string("var")])
    |> ignore(whitespace)
    |> concat(var_declare)
    |> optional(space_chars)
    |> choice([assigned_var, instantiated_var])
    |> tag(:variable)
  )

  # [async] function, function*

  defcombinatorp(
    :block,
    ignore(open_curly)
    |> repeat(
      lookahead_not(close_curly)
      |> choice([
        optional(whitespace) |> parsec(:comment),
        optional(whitespace) |> concat(quoted_string),
        optional(whitespace) |> parsec(:if_statement),
        optional(whitespace) |> parsec(:try_statement),
        optional(whitespace) |> parsec(:for_statement),
        optional(whitespace) |> parsec(:switch_statement),
        optional(whitespace) |> parsec(:function_statement),
        optional(whitespace) |> parsec(:variable_statement) |> optional(eq),
        optional(whitespace) |> parsec(:return_statement),
        optional(whitespace) |> parsec(:throw_statement),
        optional(whitespace) |> parsec(:break_statement),
        optional(whitespace) |> parsec(:continue_statement),
        optional(whitespace) |> parsec(:function_call),
        optional(whitespace) |> parsec(:label_statement),
        parsec(:block),
        ignore(whitespace),
        ascii_string([not: ?{, not: ?}], min: 1) |> concat(whitespace),
        ascii_string([not: ?{, not: ?}], min: 1)
      ])
    )
    |> wrap()
    |> optional(whitespace)
    |> ignore(close_curly)
    |> unwrap_and_tag(:block)
  )

  defcombinatorp(
    :paren_group,
    ignore(open_paren)
    |> repeat(
      lookahead_not(close_paren)
      |> choice([
        optional(whitespace) |> parsec(:comment),
        optional(whitespace) |> concat(quoted_string),
        optional(whitespace) |> parsec(:variable_statement) |> optional(eq),
        parsec(:expression),
        ascii_string([not: ?(, not: ?)], min: 1)
      ])
    )
    |> wrap()
    |> optional(whitespace)
    |> ignore(close_paren)
  )

  defcombinatorp(:expression, parsec(:paren_group) |> unwrap_and_tag(:expression))
  defcombinatorp(:condition, parsec(:paren_group) |> unwrap_and_tag(:condition))

  gather_op = string("...") |> label("gather")

  param =
    choice([
      optional(gather_op) |> concat(line_text) |> ignore(comma) |> optional(whitespace),
      ascii_string([0..255, {:not, ?)}], min: 1)
    ])

  fn_params =
    ignore(open_paren)
    |> repeat(lookahead_not(close_paren) |> concat(param))
    |> ignore(close_paren)
    |> tag(:params)

  fn_name =
    line_text
    |> tag(:fn_name)

  fn_declaration =
    fn_name
    |> optional(space_chars)
    |> concat(fn_params)
    |> optional(space_chars)
    |> concat(parsec(:block))

  defcombinatorp(
    :function_statement,
    optional(async_decorator)
    |> choice([
      string("function*") |> label("generator kw"),
      string("function") |> label("function kw")
    ])
    |> concat(space_chars)
    |> concat(fn_declaration)
    |> tag(:function_statement)
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
    |> concat(whitespace)
    |> concat(maybe_namespaced_line_text |> tag(:extends))

  defcombinatorp(
    :class_statement,
    ignore(string("class"))
    |> concat(whitespace)
    |> concat(maybe_namespaced_line_text |> tag(:classname))
    |> optional(whitespace |> concat(extends_clause))
    |> optional(whitespace)
    |> parsec(:block)
    |> tag(:class_statement)
  )

  class_statement = parsec(:class_statement)
  # export
  defcombinatorp(
    :export_statement,
    ignore(string("export"))
    |> optional(whitespace |> concat(string("default")))
    |> concat(whitespace)
    |> choice([
      parsec(:variable_statement),
      function_statement,
      class_statement,
      whitespace,
      unknown_text
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
    optional(space_chars)
    |> concat(line_text)
    |> optional(space_chars)
    |> ignore(colon)
    |> optional(whitespace)
    |> tag(:label_statement)
  )

  root =
    choice([
      comment,
      quoted_string,
      if_statement,
      break_statement,
      continue_statement,
      with_statement,
      switch_statement,
      parsec(:return_statement),
      throw_statement,
      try_statement,
      while_statement,
      do_statement,
      for_statement,
      parsec(:label_statement),
      debugger_statement,
      parsec(:variable_statement),
      function_statement,
      class_statement,
      export_statement,
      import_meta_statement,
      import_statement,
      whitespace,
      unknown_text,
      comma,
      semi,
      open_brace,
      close_brace,
      colon,
      question_mark,
      open_paren,
      close_paren
    ])

  defparsec(
    :parse,
    optional(whitespace)
    |> repeat(root)
    |> eos()
  )

  defp line_text_to_string([char | _] = line_text) when is_integer(char),
    do: List.to_string(line_text)

  defp line_text_to_string([char, rest]) when is_integer(char), do: List.to_string([char]) <> rest
end
