require 'set'

# finds the right counterpart of a left bracket
# returns input.length if it coudn't find it
def matching_bracket(input, index)
  return nil if input.nil? or index.nil?
  return nil unless index >= 0 and index < input.length
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
  return nil if i == input.length
  i
end

def bstrip(input) # if any
  return nil if input.nil?
  input.strip!
  if input.start_with?('(') then
    i = matching_bracket(input, 0)
    if i == input.length-1 then
      return bstrip(input[1..-2]) # trim off outer backets
    elsif i.nil? then
      return nil # unmatched left parenthesis
    end
  end
  input
end

# splits on 'v' or '&', but not within nested brackets
# returns delimiters
def split_clause(input)
  return nil if input.nil?
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
    return nil if level < 0 # unmatched right parenthesis
  end
  strings.push(word)
end

# matches any number of negations
def term?(input)
  (input =~ /^-*A\d+$/) === 0
end

# matches at most 1 negation
def literal?(input)
  (input =~ /^-?A\d+$/) === 0
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

def pl?(input)
  input.strip!
  input = input[1..-1] while input =~ /^-+\(/
  terms = split_clause(bstrip(input))
  return false if terms.nil?
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

def clause?(input)
  terms = split_clause(bstrip(input))
  return false if terms.nil?
  terms.each_with_index do |string, i|
    if i.even? then
      return false unless literal?(string)
    else
      return false unless string == 'v'
    end
  end
  true
end

def cnf?(input)
  return false unless pl?(input)
  clauses = split_clause(bstrip(input))
  return clause?(input) unless clauses.include?('&')
  clauses.each_with_index do |string, i|
    if i.even? then
      return false unless clause?(string)
    else
      return false unless string == '&'
    end
  end
  true
end

def horn_clause?(input)
  return false unless clause?(input)
  pos_count = 0
  split_clause(bstrip(input)).each_with_index do |string, i|
    if i.even? and pos?(string) then
       pos_count += 1
    end
  end
  pos_count <= 1
end

def horn?(input)
  return false unless cnf?(input)
  split_clause(bstrip(input)).each_with_index do |string, i|
    if i.even?
      return false unless horn_clause?(string)
    end
  end
  true
end

def clause_set(input)
  return nil unless clause?(input)
  set = '{'
  split_clause(bstrip(input)).each_with_index do |string, i|
    set += string if i.even?
  end
  set += '}'
end

def set_notation(input)
  return nil unless cnf?(input)
  return "{#{clause_set(input)}}" if clause?(input)
  set = '{';
  split_clause(bstrip(input)).each_with_index do |string, i|
    set += clause_set(string) if i.even?
  end
  set += '}'
end

def valid_clause?(input)
  (input =~ /^{(-?A\d+)*}$/) == 0
end

def valid_goal?(input)
  (input =~ /^{(-A\d+)*}$/) == 0
end

def neg_only(input)
  nil if input.nil?
  input.scan(/-A\d+/).join
end

$LIT = /-?A\d+/
$CLAUSE = /[^{}]+/

def sld_res?(input, goal)
  puts "#{input} -> #{goal}"
  return nil if input.nil? or goal.nil?
  return nil unless valid_goal?(goal)

  # for each goal literal
  goal.scan(/-A\d+/) do |neg|
    pos = neg[1..-1]

    # for each clause
    input.scan($CLAUSE) do |clause|
      if clause.scan($LIT).include?(pos) then
        new_goal = goal.sub(neg,neg_only(clause))
        puts "\tsub-goal  => #{new_goal}"
        return true if sld_res?(input, new_goal)
        puts 'Backtracking'
      end
    end
  end
  return goal.eql? '{}'
end

def contains?(input,set)
  input.scan($CLAUSE) do |clause|
    return true if clause.scan($LIT).to_set == set
  end
  false
end

def union_back(input,set)
  return input if contains?(input,set)
  "{#{input[1..-2]}{#{set.to_a.join}}}"
end

def union_front(input,set)
  return input if contains?(input,set)
  "{{#{set.to_a.join}}#{input[1..-2]}}"
end

def pos(input)
  return input[1..-1] if neg?(input)
  input
end

def neg(input)
  return '-'+input if pos?(input)
  input
end

def tautology?(set)
  set.each do |x|
    return true if neg?(x) and set.include?(pos(x))
  end
  false
end

def gen_res?(input)
  puts "#{input}"
  return nil if input.nil?
  clauses = input.scan($CLAUSE)
  clauses[0..-2].each_with_index do |a, i|
    clauses[i+1..-1].each do |b|
      next if a == b
      puts "Comparing #{a} with #{b}"
      c1 = a.scan($LIT)
      c2 = b.scan($LIT)
      c1.each do |l1|
        c2.each do |l2|
          next if neg?(l1) == neg?(l2) or pos(l1) != pos(l2)
          puts "\t\tResolve on #{pos(l1)}"
          r = Set.new
          r += c1 - [l1]
          r += c2 - [l2]
          return true if r.empty?
          return gen_res?(union_front(input,r)) unless tautology?(r) or contains?(input,r)
        end
      end
    end
  end
  false
end
