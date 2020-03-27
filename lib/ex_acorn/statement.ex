defmodule ExAcorn.Statement do
  import NimbleParsec

  # utils
  whitespace = ascii_string([?\s, ?\t, ?\n, ?\r], min: 1) |> ignore() |> label("whitespace")
  space_chars = ascii_string([?\s, ?\t, ?\r], min: 1) |> ignore() |> label("space_chars")
  eol = ascii_char([?\n]) |> ignore() |> label("eol")
  semi = ascii_char([?;]) |> tag(:semi)

  open_curly = ascii_char([?{])
  close_curly = ascii_char([?}])

  open_brace = open_curly |> tag(:open_brace)
  close_brace = close_curly |> tag(:close_brace)

  # ascii_string(
  #     [10..255, {:not, ?}}, {:not, ?{}],
  #     min: 1
  #   )
  #   |> tag(:unknown_text)

  # block =
  #   ignore(open_curly)
  #   |> repeat(lookahead_not(close_curly) |> )
  #   |> concat(close_curly)
  #   |> tag(:block)

  colon = ascii_char([?:]) |> tag(:colon)
  comma = ascii_char([?,]) |> tag(:comma)
  eq = ascii_char([?=]) |> tag(:eq)
  question_mark = ascii_char([??]) |> tag(:question_mark)

  double_quote = ascii_char([?"]) |> ignore() |> label("double_quote")
  single_quote = ascii_char([?']) |> ignore() |> label("single_quote")
  backtick_quote = ascii_char([?`]) |> ignore() |> label("backtick_quote")

  double_quoted_text =
    double_quote
    |> repeat(lookahead_not(double_quote) |> concat(ascii_string([0..255, {:not, ?"}], min: 1)))
    |> concat(double_quote)
    |> tag(:quoted_string)

  single_quoted_text =
    single_quote
    |> repeat(lookahead_not(single_quote) |> concat(ascii_string([0..255, {:not, ?'}], min: 1)))
    |> concat(single_quote)
    |> tag(:quoted_string)

  backtick_quoted_text =
    backtick_quote
    |> repeat(lookahead_not(backtick_quote) |> concat(ascii_string([0..255, {:not, ?`}], min: 1)))
    |> concat(backtick_quote)
    |> tag(:quoted_template)

  quoted_string =
    choice([
      double_quoted_text,
      single_quoted_text,
      backtick_quoted_text
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

  comment = choice([inline_comment, block_comment]) |> tag(:comment)

  line_text =
    ascii_char([?$, ?_, ?a..?z, ?A..?Z])
    |> optional(ascii_string([?$, ?_, ?a..?z, ?A..?Z, ?0..?9], min: 1))
    |> reduce({:line_text_to_string, []})
    |> label("line_text")

  open_paren = ascii_char([?(]) |> tag(:open_paren)
  close_paren = ascii_char([?)]) |> tag(:close_paren)

  async_decorator = string("async") |> concat(whitespace) |> label("async")

  identifier = line_text |> optional(semi) |> label("identifier")

  # maybe_identifier =
  #   choice([
  #     identifier,
  #     semi,
  #     empty()
  #   ])

  # tokens
  # ;
  # empty_statement = semi |> replace(tag(:empty_statement))
  # {
  # block_start = open_brace |> replace(tag(:block_start))
  # block_end = close_brace |> replace(tag(:block_end))

  # if
  if_statement = string("if") |> tag(:if_statement)

  # break
  break_statement =
    string("break")
    |> tag(:break_statement)

  # continue
  continue_statement =
    string("continue")
    |> tag(:continue_statement)

  # with
  with_statement = string("with") |> tag(:with_statement)
  # switch
  switch_statement = string("switch") |> tag(:switch_statement)
  # return
  return_statement = string("return") |> tag(:return_statement)
  # throw
  throw_statement = string("throw") |> tag(:return_statement)
  # try
  try_statement = string("try") |> tag(:try_statement)
  # while
  while_statement = string("while") |> tag(:while_statement)
  # do
  do_statement = string("do") |> tag(:do_statement)
  # for, for..in, for..of
  for_statement = string("for") |> tag(:for_statement)
  # debugger
  debugger_statement = string("debugger") |> tag(:debugger_statement)
  # const, var, let
  var_declare = line_text |> tag(:var_declare)
  multiple_decl_separator = comma |> optional(whitespace)

  variable_statement =
    choice([string("let"), string("const"), string("var")])
    |> ignore(whitespace)
    |> concat(var_declare)
    |> concat(ascii_string([?\s, ?\t], min: 0) |> ignore() |> label("whitespace"))
    |> repeat(ignore(multiple_decl_separator) |> concat(var_declare))
    |> tag(:variable_statement)

  # [async] function, function*

  defcombinatorp(
    :block,
    ignore(open_curly)
    |> repeat(
      lookahead_not(close_curly)
      |> choice([parsec(:block), ascii_string([not: ?{, not: ?}], min: 1)])
    )
    |> wrap()
    |> optional(whitespace)
    |> ignore(close_curly)
    |> tag(:block)
  )

  fn_params =
    open_paren
    |> concat(ascii_string([0..255, {:not, ?)}], min: 0))
    |> concat(close_paren)
    |> tag(:params)

  fn_body =
    parsec(:block)
    |> tag(:fn_block)

  fn_name =
    line_text
    |> tag(:fn_name)

  fn_declaration =
    fn_name
    |> optional(space_chars)
    |> concat(fn_params)
    |> optional(space_chars)
    |> concat(fn_body)

  function_statement =
    optional(async_decorator)
    |> choice([
      string("function*") |> label("generator kw"),
      string("function") |> label("function kw")
    ])
    |> concat(space_chars)
    |> concat(fn_declaration)
    |> tag(:function_statement)

  # class
  class_statement = string("class") |> tag(:class_statement)
  # export
  export_statement = string("export") |> tag(:export_statement)
  # import.meta
  import_meta_statement = string("import.meta") |> tag(:import_meta_statement)
  # import
  import_statement = string("import") |> tag(:import_statement)
  # label:
  label_statement = identifier |> optional(whitespace) |> concat(colon) |> tag(:label_statement)

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

  root =
    choice([
      comment,
      quoted_string,
      if_statement,
      break_statement,
      continue_statement,
      with_statement,
      switch_statement,
      return_statement,
      throw_statement,
      try_statement,
      while_statement,
      do_statement,
      for_statement,
      debugger_statement,
      variable_statement,
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
