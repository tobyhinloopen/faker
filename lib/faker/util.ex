defmodule Faker.Util do
  @digit ~w/0 1 2 3 4 5 6 7 8 9/
  @lowercase_alphabet ~w/a b c d e f g h i j k l m n o p q r s t u v w x y z/
  @uppercase_alphabet ~w/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/

  @doc """
  Pick a random element from the list
  """
  @spec pick([any]) :: any
  def pick(list) do
    Enum.at(list, :crypto.rand_uniform(0, Enum.count(list)))
  end

  @doc """
  Execute fun n times with the index as first param and return the results as a list
  """
  @spec list(integer, ((integer) -> any)) :: [any]
  def list(n, fun) when is_function(fun, 1) do
    Enum.map(0..(n-1), &fun.(&1))
  end
  def list(n, fun) when is_function(fun, 0) do
    Enum.map(0..(n-1), fn _ -> fun.() end)
  end

  @doc """
  Execute fun n times with the index as first param and join the results with joiner

  ## Examples

      join(3, &)
      date_of_birth(1) #=> ~D[2015-12-06]
      date_of_birth(10..19) #=> ~D[2004-05-15]
  """
  @spec join(integer, binary, ((integer) -> binary)) :: binary
  def join(n, joiner \\ "", fun) do
    Enum.join(list(n, fun), joiner)
  end

  @doc """
  Get a random digit as a string; one of 0-9
  """
  @spec digit() :: binary
  def digit do
    pick @digit
  end

  @doc """
  Get a random alphabet character as a string; one of a-z or A-Z
  """
  @spec alphabet() :: binary
  def alphabet do
    pick [@lowercase_alphabet|@uppercase_alphabet]
  end

  @doc """
  Get a random lowercase character as a string; one of a-z
  """
  @spec lower_alphabet() :: binary
  def lower_alphabet do
    pick @lowercase_alphabet
  end

  @doc """
  Get a random uppercase character as a string; one of A-Z
  """
  @spec upper_alphabet() :: binary
  def upper_alphabet do
    pick @uppercase_alphabet
  end

  @doc """
  Cycle randomly through the given list with guarantee every element of the list is used once before
  elements are being picked again. This is done by keeping a list of remaining elements that have
  not been picked yet. The list of remaining element is returned, as well as the randomly picked
  element.

  ## Example

      {a, cycle_state} = cycle ~w(1 2 3)
      {b, cycle_state} = cycle ~w(1 2 3), cycle_state
      {c, cycle_state} = cycle ~w(1 2 3), cycle_state
      [a, b, c] #=> [3, 1, 2]
  """
  @spec cycle([any], any) :: {any, any}
  def cycle(_list, _state \\ nil)
  def cycle(list, nil), do: cycle(list, [])
  def cycle(list, []), do: cycle(list, Enum.shuffle(list))
  def cycle(_original_list, [h|t]), do: {h, t}

  @doc """
  Format a string with randomly generated data. Format specifiers are replaced by random values. A
  format specifier follows this prototype:

      %[length]specifier

  The following specifier rules are present by default:

    - **d**: digits 0-9
    - **a**: lowercase alphabet a-z
    - **A**: uppercase alphabet A-Z

  The specifier rules can be overriden using the second argument.

  ## Examples

      format("%2d-%3d %a%A %2d%%") #=> "74-381 sK 32%"
      format("%8nBATMAN", n: fn() -> "nana " end) #=> "nana nana nana nana nana nana nana nana BATMAN"
  """
  def format(format_str, rules \\ [d: &digit/0, A: &upper_alphabet/0, a: &lower_alphabet/0]) do
    Regex.replace(~r/%(?:%|(\d*)([a-zA-Z]))/, format_str, &format_replace(&1, &2, &3, rules))
  end

  defp format_replace("%%", _, _, _), do: "%"
  defp format_replace(_, "", rule_char, rules) do
    format_replace(nil, 1, rule_char, rules)
  end
  defp format_replace(_, length_str, rule_char, rules) when is_binary(length_str) do
    format_replace(nil, String.to_integer(length_str), rule_char, rules)
  end
  defp format_replace(_, n, rule_char, rules) when is_integer(n) do
    rule_key = String.to_existing_atom(rule_char)
    case rules[rule_key] do
      fun when is_function(fun) -> join(n, fun)
      _ -> raise "Rule #{rule_key} not found or not a function"
    end
  end
end
