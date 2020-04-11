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
        |> choice([
          string("\""),
          ascii_string([0..255, {:not, ?"}], min: 1)
        ])
      )
      |> concat(double_quote())
      |> optional(semi())
      |> tag(:quoted_string),
      single_quote()
      |> repeat(
        lookahead_not(single_quote())
        |> choice([
          string("\'"),
          ascii_string([0..255, {:not, ?'}], min: 1)
        ])
      )
      |> concat(single_quote())
      |> optional(semi())
      |> tag(:quoted_string),
      backtick_quote()
      |> repeat(
        lookahead_not(backtick_quote())
        |> choice([
          string("\`"),
          ascii_string([0..255, {:not, ?`}], min: 1)
        ])
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

  def paren_group(children, traverse_mapper \\ {ExAcorn.Conflict, :base, []})
      when is_list(children) do
    ignore(open_paren())
    |> repeat(
      lookahead_not(close_paren())
      |> choice(children ++ [non_control_char(), ascii_char(not: ?)) |> tag(:unknown)])
    )
    |> post_traverse(traverse_mapper)
    |> wrap()
    |> optional(whitespace())
    |> ignore(close_paren())
  end

  def curly_group(children, traverse_mapper \\ {ExAcorn.Conflict, :noop, []})
      when is_list(children) do
    ignore(open_curly())
    |> repeat(
      lookahead_not(close_curly())
      |> optional(whitespace())
      |> choice(children ++ [non_control_char(), ascii_char(not: ?}) |> tag(:unknown)])
    )
    |> post_traverse(traverse_mapper)
    |> wrap()
    |> optional(whitespace())
    |> ignore(close_curly())
  end

  def bracket_group(children, traverse_mapper \\ {ExAcorn.Conflict, :noop, []})
      when is_list(children) do
    ignore(open_bracket())
    |> optional(whitespace())
    |> repeat(
      lookahead_not(close_bracket())
      |> optional(whitespace())
      |> choice(
        children ++
          [
            ignore(ascii_char([?,])),
            non_control_char(),
            ascii_char(not: ?]) |> tag(:unknown)
          ]
      )
    )
    |> post_traverse(traverse_mapper)
    |> wrap()
    |> optional(whitespace())
    |> ignore(close_bracket())
    |> label("bracket_group")
  end

  def local_block(inner_combinator \\ empty()) do
    ignore(open_curly())
    |> optional(whitespace())
    |> repeat(
      lookahead_not(close_curly())
      |> optional(whitespace())
      |> choice([
        inner_combinator,
        non_control_char(),
        ascii_char(not: ?}) |> tag(:unknown)
      ])
    )
    |> wrap()
    |> optional(whitespace())
    |> ignore(close_curly())
    |> label("local_block")
  end
end
