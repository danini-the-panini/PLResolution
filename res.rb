def cnf?(input) input.strip!
  error unless pl?(input)
  clauses = split_clause(remove_outer_brackets(input.strip))
  clauses.each_with_index do |string, i|
    if i.even? then
      return false unless clause?(string)
    else
      return false unless string == '&'
    end
  end
  true
end

def clause?(input)
  terms = split_clause(remove_outer_brackets(input.strip))
  terms.each_with_index do |string, i|
    if i.even? then
      return false unless literal?(string)
    else
      return false unless string == 'v'
    end
  end
  true
end

def pl?(input)
  input = input[1..-1] while input =~ /^-+\(/
  terms = split_clause(remove_outer_brackets(input.strip))
  return false unless terms.length.odd?
  return term?(terms.first) if terms.length == 1
  terms.each_with_index do |string, i|
    if i.even? then
      return false unless pl?(string)
    else
      return false unless op?(string)
    end
  end
  true
end

# matches any number of negations
def term?(input)
  (input =~ /^-*A[0-9]+$/) === 0
end

# matches at most 1 negation
def literal?(input)
  (input =~ /^-?A[0-9]+$/) === 0
end

def pos?(input)
  literal?(input) && input.start_with?('A')
end

def neg?(input)
  literal?(input) && input.start_with?('-')
end

def op?(input)
  ['v','&'].include?(input)
end

def remove_outer_brackets(input) # if any
  if input.start_with?('(') then
    i = matching_bracket(input, 0)
    if i == input.length-1 then
      input = input[1..-2] # trim off outer backets
    elsif i == input.length then
      error # unmatched left parenthesis
    end
  end
  input
end

# finds the right counterpart of a left bracket
def matching_bracket(input, index)
  level = 1
  i = index
  while (level > 0) do
    i = i.next
    case input[i]
    when '('
      level = level.next
    when ')'
      level = level.pred
    when nil
      level = 0
    end
  end
  i
end

# splits on 'v' or '&', but not within nested brackets
# returns delimiters
def split_clause(input)
  strings = []
  word = ''
  level = 0
  input.each_char do |c|
    case c
    when '('
      level = level.next
      word += c
    when ')'
      level = level.pred
      word += c
    when 'v', '&'
      if level == 0 then
        strings.push(word)
        strings.push(c.to_s)
        word = ''
      else
        word += c
      end
    else
      word += c
    end
    error if level < 0 # unmatched right parenthesis
  end
  strings.push(word)
end

def error
  puts 'error!'
  #exit(1)
end
