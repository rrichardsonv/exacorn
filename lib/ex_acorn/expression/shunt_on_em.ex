defmodule ExAcorn.ShuntOnEm do
    @moduledoc """
    Shunting yard algorithm as explained at https://en.wikipedia.org/wiki/Shunting-yard_algorithm

    Refactored and repurposed from https://gist.github.com/pixyj/73bebd14be17ce680e9219f642044964

    For use, primarily in traversing tokens produced by the wonderful nimbleparsec
    ## Examples
    ```
    iex> tokens = [
        {:left, [val: "(", rank: 21]},
        {:num, [val: "3"]},
        {:op, [val: "*", rank: 15, key: :binary_expression]},
        {:num, [val: "2"]},
        {:op, [val: "+", rank: 14, key: :binary_expression]},
        {:num, [val: "5"]},
        {:right, [val: ")", rank: 21]},
        {:op, [val: "*", rank: 15, key: :binary_expression]},
        {:num, [val: "4"]},
    ]
    iex> tokens |> ShuntingYard.parse()
    [
        binary_expression: [
            operator: "*",
            right: {:num, [val: "4"]},
            left: {:binary_expression,
            [
            operator: "+",
            right: {:num, [val: "5"]},
            left: {:binary_expression,
                [operator: "*", right: {:num, [val: "2"]}, left: {:num, [val: "3"]}]}
            ]}
        ]
    ]
    ```
    """

    @type token :: {atom(), Keyword.t()}

    @spec add_to_queue(token, [token()], integer()) :: [token()]
    defp add_to_queue(token, output_queue, _call_id) do
        output_queue ++ [token]
    end

    @spec has_parens?([token()]) :: boolean()
    defp has_parens?(stack) do
        Enum.any?(stack, fn
            {k, _} when k in [:left, :right] -> true
            _ -> false
        end)
    end

    @spec parse([token()]) :: [token()]
    def parse(tokens) do
        {_, output_queue, stack} = parse_impl(tokens, [], [])

        if has_parens?(stack) do
            raise "Mismatched parens error"
        end

        to_tree(output_queue, stack)
    end

    defp to_tree(queue, stack), do: do_to_tree(Enum.reverse(queue), stack)

    defp do_to_tree(queue, []), do: queue
    defp do_to_tree(queue, [token | stack]) do
        {children, rest} = Enum.split(queue, 2)
        do_to_tree([format_op_token(token, children) | rest], stack)
    end

    defp format_op_token({:op, props}, children) do
        {token_key, props} = Keyword.pop(props, :key)

        token_props =
            Enum.reduce(props, [], fn
                {:val, val}, acc ->
                    [{:operator, val} | acc]
                {:rank, _}, acc ->
                    acc
                entry, acc ->
                    acc ++ [entry]
            end)

        {token_key, add_children(token_props, children)}
    end

    defp add_children(props, [right, left]), do: props ++ [right: right, left: left]

    @spec parse_impl([token()], [token()], [token()]) :: {[token()], [token()], [token()]}
    def parse_impl([], output_queue, stack), do: {[], output_queue, stack}
    def parse_impl([first | rest], output_queue, stack) do
        {output_queue, stack} = add_token(first, output_queue, stack)
        parse_impl(rest, output_queue, stack)
    end

    @spec add_token(token(), [token()], [token()]) :: {[token()], [token()]}
    def add_token({:left, _} = token, output_queue, stack),
        do: {output_queue, [token | stack]}

    def add_token({:right, _} = token, output_queue, stack),
        do: add_right_paren(token, output_queue, stack)

    def add_token({:op, _} = token, output_queue, stack),
        do: add_operator(token, output_queue, stack)

    def add_token(token, output_queue, stack),
        do: {add_to_queue(token, output_queue, 1), stack}

    @spec add_right_paren(token(), [token()], [token()]) :: {[token()], [token()]}
    defp add_right_paren(_token, _output_queue, []),
        do: raise "Matching parens not found"

    defp add_right_paren(_token, output_queue, [{:left, _} | rest]),
        do: {output_queue, rest}

    defp add_right_paren(token, output_queue, [top_op | rest]) do
        condensed_queue =
            output_queue
            |> to_tree([top_op])
            |> Enum.reverse()

        add_right_paren(token, condensed_queue, rest)
    end

    @spec add_operator(token(), [token()], [token()]) :: {[token()], [token()]}
    defp add_operator(token, output_queue, stack) do
        {partial_queue, s1} = pop_higher_precendence_ops_to_queue(token, [], stack)

        next_queue =
            output_queue
            |> to_tree(partial_queue)
            |> Enum.reverse()

        {next_queue, [token | s1]}
    end

    defp pop_higher_precendence_ops_to_queue(_token, q, []),
        do: {q, []}

    defp pop_higher_precendence_ops_to_queue(_token, q, [{op_type, _} | _] = stack)
        when op_type in [:right, :left], do: {q, stack}

    defp pop_higher_precendence_ops_to_queue(token, q, [top_op | rest] = stack) do
        [token, top_op]
        |> Enum.map(fn {_, props} -> props end)
        |> Enum.map(&Keyword.fetch!(&1, :rank))
        |> case do
            [token_rank, top_rank] when token_rank <= top_rank ->
                pop_higher_precendence_ops_to_queue(token, q ++ [top_op], rest)
            _ ->
                {q, stack}
        end
    end
end
