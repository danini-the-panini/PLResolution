require './res'
require 'test/unit'

class TestRes < Test::Unit::TestCase

  def test_split_clause
    assert_equal(['A1'],split_clause('A1'))
    assert_equal(['A1','v','A2','&','A3'],split_clause('A1vA2&A3'))
    assert_equal(['(A1vA2&A3)','v','A4','&','(A1vA2&A3)'],split_clause('(A1vA2&A3)vA4&(A1vA2&A3)'))
    assert_nil(split_clause('A1v(A2&A3))'))
    assert_nil(split_clause(nil))
  end

  def test_matching_bracket
    assert_equal(9,matching_bracket('asdf(asdf)asdf',4))
    assert_nil(matching_bracket('asdf(as',4))
    assert_nil(matching_bracket('asdf',2))
    assert_nil(matching_bracket('asdf',-1))
    assert_nil(matching_bracket(nil,1))
  end

  def test_bstrip
    assert_equal('blahblah',bstrip('(blahblah)'))
    assert_equal('blahblah',bstrip('((blahblah))'))
    assert_equal('',bstrip('()'))
    assert_nil(bstrip('(blahblah'))
    assert_nil(bstrip(nil))
  end

  def test_clause
    assert(clause?('A1vA2vA3'))
    assert(!clause?('A1vA2&A3'))
    assert(!clause?('A1v(A2vA3)'))
    assert(!clause(nil))
  end

  def test_pl
    assert(pl?('A1'))
    assert(pl?('A1vA2&A3'))
    assert(pl?('(A1vA2)&A3'))
    assert(!pl?('A1v'))
    assert(!pl?('vA1'))
    assert(!pl?('A3&(A1vA2'))
    assert(!pl?('A1vA2)&A3'))
  end

  def test_clause
    assert(clause?('A1'))
    assert(clause?('A1vA2'))
    assert(!clause?('A1&A2'))
    assert(!clause?('(A1&A2)vA3'))
  end

  def test_cnf
    assert(cnf?('A1'))
    assert(cnf?('-A1&(A1vA2)'))
    assert(cnf?('(A1vA2)&(-A2vA3v-A4)&(A4vA5)'))
    assert(cnf?('A1vA2'))
    assert(cnf?('A1&A2'))

    assert(!cnf?('-(A1vA2)'))
    assert(!cnf?('(A1&A2)vA3'))
    assert(!cnf?('A1&(A2v(A3&A4))'))
  end

  def test_horn_clause
    assert(horn_clause?('-A1v-A2vA3'))
    assert(horn_clause?('-A1v-A2v-A3'))
    assert(horn_clause?('A1'))
    assert(!horn_clause?('-A1vA2vA3'))
  end

  def test_horn
    assert(horn?('(-A1v-A2vA3)&A1&(-A2v-A3v-A4)'))
    assert(!horn?('(-A1vA2vA3)&A1'))
  end

  def test_clause_set
    assert_equal('{A1}',clause_set('A1'))
    assert_equal('{A1A2}',clause_set('A1vA2'))
    assert_nil(clause_set('A1&A2'))
    assert_nil(clause_set(nil))
  end

  def test_set_notation
    assert_equal('{{A1}}',set_notation('A1'))
    assert_equal('{{A1}{A2}}',set_notation('A1&A2'))
    assert_equal('{{A1A2}}',set_notation('A1vA2'))
    assert_equal('{{A1A2}{-A1}{-A2A3}}',set_notation('(A1vA2)&-A1&(-A2vA3)'))
    assert_nil(set_notation('-A1&(A2v(A3&-A4))'))
    assert_nil(nil)
  end

end
