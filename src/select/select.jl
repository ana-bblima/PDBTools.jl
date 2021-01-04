#
# Function to perform the most important selections that are used in solute-solvent
# analysis
#

# Main function: receives the atoms vector and a julia function to select

function select( atoms :: Vector{Atom}; by=all)
  selected_atoms = typeof(atoms)(undef,0)
  for atom in atoms
    if by(atom)
      push!(selected_atoms,atom)
    end
  end
  return selected_atoms
end

# Given a selection string

function select( atoms :: Vector{Atom}, selection :: String )
  query = parse_query(selection)
  return select(atoms, by = atom -> apply_query(query,atom))
end

#
# Return indexes only
#
function selindex( atoms :: Vector{Atom}; by=all)
  indexes = Vector{Int64}(undef,0)
  for atom in atoms
    if by(atom)
      push!(indexes,atom.index)
    end
  end
  return indexes
end

function selindex( atoms :: Vector{Atom}, selection :: String )
  query = parse_query(selection)
  return selindex(atoms, by = atom -> apply_query(query,atom))
end

# Comparison operators

const operators = ( " = " =>  (x,y) -> isequal(x,y),
                    " < " =>  (x,y) -> isless(x,y),
                    " > " =>  (x,y) -> isless(y,x), 
                    " <= " => (x,y) -> (! isless(y,x)),
                    " >= " => (x,y) -> (! isless(x,y)),
                   ) 

using Parameters

#
# Numerical syntax keywords
#

@with_kw struct NumericalKeyword
  syntax_name :: String
  name :: String # Disambiguated if necessary
  symbol :: Symbol
  operations :: Tuple
end

function (key :: NumericalKeyword)(str)
  @unpack name, operations, symbol = key
  parse_keyword(name, str, op) = parse(Int, match(name*op*r"([0-9]*)", str)[1])  
  for op in operations
    if occursin(name*op.first, str)
      k = parse_keyword(name,str,op.first)
      return atom -> op.second(getfield(atom,symbol),k)
    end
  end
  nothing
end

numerical_keywords = [ NumericalKeyword("index", "index", :index, operators), 
                       NumericalKeyword("index_pdb", "index_pdb", :index_pdb, operators),
                       NumericalKeyword("resnum", "resnum", :resnum, operators),
                       NumericalKeyword("residue", "residue", :residue, operators),
                       NumericalKeyword("b", "b", :b, operators),
                       NumericalKeyword("occup", "occup", :occup, operators),
                       NumericalKeyword("model", "model", :model, operators),
                     ]

#
# String syntax keywords
#

@with_kw struct StringKeyword
  syntax_name :: String
  name :: String # Disambiguated if necessary
  symbol :: Symbol
  operations :: Tuple
end

function (key :: StringKeyword)(str)
  @unpack name, operations, symbol = key
  parse_keyword(name, str, op) = match(name*op*r"([A-Z,0-9]*)", str)[1] 
  for op in operations
    if occursin(name*op.first, str)
      k = parse_keyword(name,str,op.first)
      return atom -> op.second(getfield(atom,symbol),k)
    end
  end
  nothing
end

string_keywords = [ StringKeyword("name", "name", :name, operators), 
                    StringKeyword("segname", "SEGNAME", :segname, operators), 
                    StringKeyword("resname", "RESNAME", :resname, operators), 
                    StringKeyword("chain", "chain", :chain, operators), 
                    StringKeyword("element", "element", :element, operators), 
                  ]

#
# Special functions keywords
#

@with_kw struct SpecialKeyword
  syntax_name :: String
  name :: String # Disambiguated if necessary
  fname :: Function
end

(key :: SpecialKeyword)(str) = key.fname

special_keywords = [ SpecialKeyword("water", "water", iswater), 
                     SpecialKeyword("protein", "protein", isprotein), 
                     SpecialKeyword("polar", "polar", ispolar), 
                     SpecialKeyword("nonpolar", "NONPOLAR", isnonpolar), 
                     SpecialKeyword("basic", "basic", isbasic), 
                     SpecialKeyword("isacidic", "isacidic", isacidic), 
                     SpecialKeyword("charged", "charged", ischarged), 
                     SpecialKeyword("aliphatic", "aliphatic", isaliphatic), 
                     SpecialKeyword("aromatic", "aromatic", isaromatic), 
                     SpecialKeyword("hydrophobic", "hydrophobic", ishydrophobic), 
                     SpecialKeyword("neutral", "neutral", isneutral), 
                     SpecialKeyword("backbone", "backbone", isbackbone), 
                     SpecialKeyword("sidechain", "SIDECHAIN", issidechain), 
                     SpecialKeyword("all", "all", isequal), 
                   ]

#
# Remove trailing and multiple spaces
#

function remove_spaces(str)
  str = split(str)
  s = str[1]
  for i in 2:length(str)
    s = s*' '*str[i]
  end
  s
end

#
# Keywords that have to be disambiguated 
#

function disambiguate(selection)
  for key in numerical_keywords
    selection = replace(selection,key.syntax_name => key.name)
  end
  for key in string_keywords
    selection = replace(selection,key.syntax_name => key.name)
  end
  s
end

# parse_query and apply_query are a very gentle contribution given by 
# CameronBieganek in https://discourse.julialang.org/t/parsing-selection-syntax/43632/9
# while explaining to me how to creat a syntex interpreter

function parse_query(selection)
  # disambiguate keywords
  s = remove_spaces(selection) 
  s = disambiguate(s)
  try
    if occursin("or", s)
      (|, parse_query.(split(s, "or"))...)
    elseif occursin("and", s)
      (&, parse_query.(split(s, "and"))...)
    elseif occursin("not", s)
      rest = match(r".*not(.*)", s)[1]
      (!, parse_query(rest))

    # keywords 
    else
      for key in numerical_keywords
        occursin(key.name, s) && return key(s)
      end
      for key in string_keywords
        occursin(key.name, s) && return key(s)
      end
      for key in special_keywords
        occursin(key.name, s) && return key(s)
      end
      parse_error()
    end

  # Error in the syntax
  catch err
    parse_error()
  end
end

function apply_query(q, a)
  if !(q isa Tuple)
    q(a)
  else
    f, args = Iterators.peel(q)
    f(apply_query.(args, Ref(a))...)
  end
end         

#
# Simple error message (https://discourse.julialang.org/t/a-julia-equivalent-to-rs-stop/36568/13)
#

struct NoBackTraceException
    exc::Exception
end

function Base.showerror(io::IO, ex::NoBackTraceException, bt; backtrace=true)
    Base.with_output_color(get(io, :color, false) ? Base.error_color() : :nothing, io) do io
        showerror(io, ex.exc)
    end
end

parse_error() = throw(NoBackTraceException(ErrorException("Error parsing selection. Use spaces, parenthesis not supported.")))

