defmodule ExAcorn.Common do
  import NimbleParsec
  import ExAcorn.Utils

  # ---------------------------
  # Quotes
  # ---------------------------

  def double_quoted_text do
    double_quote()
    |> repeat(
      lookahead_not(double_quote())
      |> concat(ascii_string([0..255, {:not, ?"}], min: 1))
    )
    |> concat(double_quote())
    |> tag(:quoted_string)
  end

  def single_quoted_text do
    single_quote()
    |> repeat(
      lookahead_not(single_quote())
      |> concat(ascii_string([0..255, {:not, ?'}], min: 1))
    )
    |> concat(single_quote())
    |> tag(:quoted_string)
  end

  def backtick_quoted_text do
    backtick_quote()
    |> repeat(
      lookahead_not(backtick_quote())
      |> concat(ascii_string([0..255, {:not, ?`}], min: 1))
    )
    |> concat(backtick_quote())
    |> tag(:quoted_template)
  end

  def quoted_string do
    choice([
      double_quote()
      |> repeat(
        lookahead_not(double_quote())
        |> concat(ascii_string([0..255, {:not, ?"}], min: 1))
      )
      |> concat(double_quote())
      |> optional(semi())
      |> tag(:quoted_string),
      single_quote()
      |> repeat(
        lookahead_not(single_quote())
        |> concat(ascii_string([0..255, {:not, ?'}], min: 1))
      )
      |> concat(single_quote())
      |> optional(semi())
      |> tag(:quoted_string),
      backtick_quote()
      |> repeat(
        lookahead_not(backtick_quote())
        |> concat(ascii_string([0..255, {:not, ?`}], min: 1))
      )
      |> concat(backtick_quote())
      |> optional(semi())
      |> tag(:quoted_template)
    ])
  end

  # ---------------------------
  # Comments
  # ---------------------------
  def inline_comment do
    ignore(string("//"))
    |> optional(space_chars())
    |> concat(ascii_string([0..255, {:not, ?\n}], min: 0))
    |> lookahead(eol())
    |> tag(:inline_comment)
  end

  def block_comment do
    ignore(string("/*"))
    |> repeat(
      lookahead_not(string("*/"))
      |> concat(
        ascii_string([0..255, {:not, ?*}], min: 1)
        |> optional(ascii_char([?*]))
        |> lookahead_not(ascii_char([?/]))
      )
    )
    |> ignore(string("*/"))
    |> tag(:block_comment)
  end

  def comment do
    choice([
      ignore(string("//"))
      |> optional(space_chars())
      |> concat(ascii_string([0..255, {:not, ?\n}], min: 0))
      |> lookahead(eol()),
      ignore(string("/*"))
      |> optional(eol())
      |> repeat(
        lookahead_not(string("*/"))
        |> choice([
          ascii_string([0..255, {:not, ?*}], min: 1),
          ascii_char([?*]) |> lookahead_not(ascii_char([?/]))
        ])
      )
      |> ignore(string("*/"))
    ])
    |> tag(:comment)
  end

  def paren_group(children) do
    ignore(open_paren())
    |> repeat(
      lookahead_not(close_paren())
      |> choice(children ++ [ascii_string([not: ?(, not: ?)], min: 1)])
    )
    |> wrap()
    |> optional(whitespace())
    |> ignore(close_paren())
  end

  def curly_group(children) when is_list(children) do
    ignore(open_curly())
    |> repeat(
      lookahead_not(close_curly())
      |> choice(children ++ [ascii_string([not: ?{, not: ?}], min: 1)])
    )
    |> wrap()
    |> optional(whitespace())
    |> ignore(close_curly())
  end

  def local_block(inner_combinator \\ empty()) do
    ignore(open_curly())
    |> optional(whitespace())
    |> repeat(
      lookahead_not(close_curly())
      |> choice([inner_combinator, ascii_string([not: ?{, not: ?}], min: 1)])
    )
    |> wrap()
    |> optional(whitespace())
    |> ignore(close_curly())
    |> label("local_block")
  end

  def variable_statement do
    choice([string("let"), string("const"), string("var")])
    |> ignore(whitespace())
    |> concat(
      line_text()
      |> concat(ascii_string([?\s, ?\t], min: 0) |> ignore() |> label("whitespace()"))
      |> repeat(ignore(comma() |> optional(whitespace())) |> concat(line_text()))
    )
    |> optional(space_chars())
    |> choice([
      ignore(eq())
      |> optional(whitespace())
      |> lookahead(non_whitespace_chars())
      |> tag(:assignment),
      expression_boundary()
      |> tag(:no_assign)
    ])
    |> tag(:variable)
  end
end
