require './res.rb'

def error
  puts "error!"
  exit(1)
end

puts "Input formula"
input = gets.chomp
error unless pl? input
if cnf? input then
  puts "CNF"
  c = clause_set input
  puts "C := #{c}"
  if horn? input then
    puts "HORN"
    puts "Input goal clause"
    goal = gets.chomp
    error unless goal_clause? goal
    puts sld_res?(c, literal_set(goal)) ? "YES" : "NO"
  else
    puts "NOT HORN"
    puts "Input query clause"
    query = gets.chomp
    error unless clause? query
    puts gen_res?("{#{c[1..-2]}#{literal_set query}}") ? "YES" : "NO"
  end
else
  puts "NOT CNF"
end
