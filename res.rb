require 'set'

# finds the right counterpart of a left bracket
# returns input.length if it coudn't find it
def matching_bracket input, index
  return nil if input.nil? or index.nil?
  return nil unless index >= 0 and index < input.length and input[index] == '('
  level = 1
  i = index
  while level > 0 do
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
  return nil if i == input.length
  i
end

# removes enclosing brackets (if any)
# bastrip '(x)' => bstrip 'x' iff the start and end brackets are matching
# bstrip 'x)' => nil
def bstrip input
  return nil if input.nil?
  input.strip!
  if input.start_with? '(' then
    i = matching_bracket(input, 0)
    if i == input.length-1 then
      return bstrip input[1..-2] # trim off outer backets
    elsif i.nil? then
      return nil # unmatched left parenthesis
    end
  end
  input
end

# splits on 'v' or '&', but not within nested brackets
# returns delimiters
def split_clause input
  return nil if input.nil?
  strings = []
  word = ''
  level = 0
  input.each_char do |c|
    case c
    when '('
      level += 1
      word << c
    when ')'
      level -= 1
      word << c
    when 'v', '&'
      if level == 0 then
        strings.push word
        strings.push c.to_s
        word = ''
      else
        word << c
      end
    else
      word << c
    end
    return nil if level < 0 # unmatched right parenthesis
  end
  strings.push word
end

# matches any number of negations
def term? input
  (input =~ /^-*A\d+$/) === 0
end

# matches at most 1 negation
def literal? input
  (input =~ /^-?A\d+$/) === 0
end

# true if the input matches a positive literal
def pos? input
  literal?(input) && input.start_with?('A')
end

# true if the input matches a negative literal
def neg? input
  literal?(input) && input.start_with?('-')
end

# true if the input matches an operator
def op? input
  ['v','&'].include? input
end

# true if the input represents a valid PL formula
def pl? input
  return false if input.nil? or input.empty?
  input.strip!
  # remove trailing negations
  input = input[1..-1] while input =~ /^-+\(/
  # (PL) => PL
  return pl? input[1..-2] if matching_bracket(input,0) == input.length-1

  terms = split_clause input
  return false if terms.nil? or terms.length.even?
  # a single term is a PL formula
  return term?(terms.first) if terms.length == 1

  terms.each_with_index do |token, i|
    if i.even? then
      return false unless pl? token
    else
      return false unless op? token
    end
  end
  true
end

# true if the input represents a clause (disjunction of literals)
def clause? input
  return false unless pl? input

  terms = split_clause bstrip(input)
  return false if terms.nil?

  terms.each_with_index do |token, i|
    if i.even? then
      return false unless literal? token
    else
      return false unless token == 'v'
    end
  end
  true
end

# true if the input is in CNF (conjunction of clauses)
def cnf? input
  return false unless pl? input

  clauses = split_clause bstrip(input)

  # a clause on its own is in CNF
  return clause? input unless clauses.include? '&'

  clauses.each_with_index do |token, i|
    if i.even? then
      return false unless clause? token
    else
      return false unless token == '&'
    end
  end
  true
end

# true if the input is a horn clause (at most one positive literal)
def horn_clause? input
  return false unless clause? input

  pos_count = 0
  split_clause(bstrip(input)).each_with_index do |token, i|
    if i.even? and pos? token then
       pos_count += 1
    end
  end
  pos_count <= 1
end

# true if the input is a horn formula (conjunction of horn clauses)
def horn? input
  return false unless cnf? input

  split_clause(bstrip(input)).each_with_index do |token, i|
    if i.even?
      return false unless horn_clause? token
    end
  end
  true
end

# converts the given input into a set of literals of the form {L1L2..Ln}
def literal_set input
  return nil unless clause? input
  set = '{'
  split_clause(bstrip(input)).each_with_index do |token, i|
    set += token if i.even?
  end
  set += '}'
end

# converts the given input into set of clauses
def clause_set input
  return nil unless cnf? input
  return "{#{literal_set input}}" if clause? input
  set = '{';
  split_clause(bstrip(input)).each_with_index do |token, i|
    set += literal_set token if i.even?
  end
  set += '}'
end

# true if the input represents a valid clause (as a set of literals)
def valid_clause? input
  (input =~ /^{(-?A\d+)*}$/) == 0
end

# true if the input represents a valid SLD goal
def valid_goal? input
  (input =~ /^{(-A\d+)*}$/) == 0
end

# returns input with all positive literals removed
def neg_only input
  nil if input.nil?
  input.scan(/-A\d+/).join
end

$LIT = /-?A\d+/
$CLAUSE = /[^{}]+/

# performs SLD resolution of the given HORN formula
def sld_res? input, goal
  puts "#{input} -> #{goal}"
  return nil if input.nil? or goal.nil?
  return nil unless valid_goal? goal

  # for each goal literal
  goal.scan $LIT do |neg|
    pos = neg[1..-1]

    # for each clause
    input.scan $CLAUSE do |clause|
      if clause.scan($LIT).include? pos then
        new_goal = goal.sub neg, neg_only(clause)
        puts "\tsub-goal  => #{new_goal}"
        return true if sld_res? input, new_goal
        puts 'Backtracking'
      end
    end
  end
  return goal.eql? '{}'
end

# true if the input contains the set
def contains? input, set
  input.scan $CLAUSE do |clause|
    return true if clause.scan($LIT).to_set == set
  end
  false
end

# appends the input with the set, if the input does not already contain the set
def union_back input, set
  return input if contains? input, set
  "{#{input[1..-2]}{#{set.to_a.join}}}"
end

# prepends input with the set, if input does not already contain the set
def union_front input, set
  return input if contains? input, set
  "{{#{set.to_a.join}}#{input[1..-2]}}"
end

#returns the positive form of the given literal
# pos -A1 => A1
# pos A1 => A1
def pos input
  return input[1..-1] if neg? input
  input
end

# returns the negative form of the given literal
# neg A1 => -A1
# neg -A1 => -A1
def neg input
  return '-'+input if pos? input
  input
end

# true if the given set includes a tautology
def tautology? set
  set.each do |x|
    return true if neg? x and set.include? pos(x)
  end
  false
end

# performs general resolution on the given set of clauses
def gen_res? input
  puts "#{input}"
  return nil if input.nil?

  # select two different clauses C1 and C2
  clauses = input.scan $CLAUSE
  clauses[0..-2].each_with_index do |a, i|
    clauses[i+1..-1].each do |b|
      c1 = a.scan $LIT
      c2 = b.scan $LIT

      # find matching literals
      c1.each do |l1|
        c2.each do |l2|
          next if neg?(l1) == neg?(l2) or pos(l1) != pos(l2)
          puts "\t\tResolve #{a} and #{b} on #{pos l1}"

          # resolvent R
          r = Set.new
          r += c1 - [l1]
          r += c2 - [l2]

          # we've reached a contradiction
          return true if r.empty?

          # "depth"
          return gen_res? union_front(input, r) unless tautology? r or contains? input, r
        end
      end
    end
  end
  false
end
