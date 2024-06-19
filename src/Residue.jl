"""
    Residue(atoms::AbstractVector{Atom}, range::UnitRange{Int})

Residue data structure. It contains two fields: `atoms` which is a vector of
`Atom` elements, and `range`, which indicates which atoms of the `atoms` vector
compose the residue.

The Residue structure carries the properties of the residue or molecule of the atoms
it contains, but it does not copy the original vector of atoms, only the residue
meta data for each residue.

### Example

```julia-repl
julia> pdb = wget("1LBD");

julia> residues = collect(eachresidue(pdb))
   Array{Residue,1} with 238 residues.

julia> resnum.(residues[1:3])
3-element Vector{Int64}:
 225
 226
 227

julia> residues[5].chain
"A"

julia> residues[8].range
52:58

```

"""
struct Residue{T<:Atom,Vec<:AbstractVector{T}} <: AbstractVector{T}
    atoms::Vec
    range::UnitRange{Int}
    name::String
    resname::String
    residue::Int
    resnum::Int
    chain::String
    model::Int
    segname::String
end
name(residue::Residue) = residue.name
resname(residue::Residue) = residue.resname
residue(residue::Residue) = residue.residue
resnum(residue::Residue) = residue.resnum
chain(residue::Residue) = residue.chain
model(residue::Residue) = residue.model
segname(residue::Residue) = residue.segname
mass(residue::Residue) = mass(@view residue.atoms[residue.range])

function Residue(atoms::AbstractVector{Atom}, range::UnitRange{Int})
    i = range[begin]
    # Check if the range effectivelly corresponds to a single residue (unsafe check)
    for j = range[begin]+1:range[end]
        if atoms[j].residue != atoms[i].residue
            error("Range $range does not correspond to a single residue or molecule.")
        end
    end
    Residue(
        atoms,
        range,
        atoms[i].resname,
        atoms[i].resname,
        atoms[i].residue,
        atoms[i].resnum,
        atoms[i].chain,
        atoms[i].model,
        atoms[i].segname,
    )
end
Residue(atoms::AbstractVector{Atom}) = Residue(atoms, 1:length(atoms))

function Base.getindex(residue::Residue, i::Int)
    i > 0 || throw(ArgumentError("Index must be in 1:$(length(residue))"))
    (i <= length(residue)) || throw(ArgumentError("Residue has $(length(residue)) atoms, tried to fetch index $i."))
    i = first(residue.range) + i - 1
    residue.atoms[i]
end

#
# Structure and function to define the eachresidue iterator
#
struct EachResidue{T<:AbstractVector{Atom}}
    atoms::T
end

"""
    eachresidue(atoms::AbstractVector{Atom})

Iterator for the residues (or molecules) of a selection. 

### Example

```julia-repl
julia> atoms = wget("1LBD");

julia> length(eachresidue(atoms))
238

julia> for res in eachresidue(atoms)
         println(res)
       end
 Residue of name SER with 6 atoms.
   index name resname chain   resnum  residue        x        y        z  beta occup model segname index_pdb
       1    N     SER     A      225        1   45.228   84.358   70.638 67.05  1.00     1       -         1
       2   CA     SER     A      225        1   46.080   83.165   70.327 68.73  1.00     1       -         2
       3    C     SER     A      225        1   45.257   81.872   70.236 67.90  1.00     1       -         3
       4    O     SER     A      225        1   45.823   80.796   69.974 64.85  1.00     1       -         4
       5   CB     SER     A      225        1   47.147   82.980   71.413 70.79  1.00     1       -         5
       6   OG     SER     A      225        1   46.541   82.639   72.662 73.55  1.00     1       -         6

 Residue of name ALA with 5 atoms.
   index name resname chain   resnum  residue        x        y        z  beta occup model segname index_pdb
       7    N     ALA     A      226        2   43.940   81.982   70.474 67.09  1.00     1       -         7
       8   CA     ALA     A      226        2   43.020   80.825   70.455 63.69  1.00     1       -         8
       9    C     ALA     A      226        2   41.996   80.878   69.340 59.69  1.00     1       -         9
                                                      ...

```

"""
eachresidue(atoms::AbstractVector{Atom}) = EachResidue(atoms)

# Collect residues default constructor
Base.collect(r::EachResidue) = collect(Residue, r)
Base.length(residues::EachResidue) = sum(1 for residue in residues)
Base.firstindex(residues::EachResidue) = 1
Base.lastindex(residues::EachResidue) = length(residues)
function Base.getindex(::EachResidue, ::Int)
    throw(ArgumentError("""\n
        The eachresidue iterator does not support indexing. 
        Use collect(eachresidue(atoms)) to get an indexable list of residues.
    """))
end

# Array interface
Base.size(residue::Residue) = (length(residue.range),)
Base.length(residue::Residue) = length(residue.range)
Base.eltype(::Residue) = Atom

#
# Iterate over residues of a structure
#
function Base.iterate(residues::EachResidue, current_atom=nothing)
    if isnothing(current_atom)
        current_atom = 1
    elseif current_atom > length(residues.atoms)
        return nothing
    end
    next_atom = current_atom + 1
    while next_atom <= length(residues.atoms) && 
          same_residue(residues.atoms[current_atom], residues.atoms[next_atom]) 
        next_atom += 1
    end
    return (Residue(residues.atoms, current_atom:next_atom-1), next_atom)
end

#
# Iterate over atoms of one residue
#
function Base.iterate(residue::Residue, current_atom=nothing)
    first_atom = index(first(residue))
    last_atom = index(last(residue))
    if isnothing(current_atom)
        current_atom = first_atom
    elseif current_atom > last_atom
        return nothing
    end
    return (residue[current_atom - first_atom + 1], current_atom + 1)
end


@testitem "Residue iterator" begin
    atoms = readPDB(PDBTools.TESTPDB, "protein")
    residues = eachresidue(atoms)
    @test length(residues) == 104
    @test name(Residue(atoms, 1:12)) == "ALA"
    @test Residue(atoms, 1:12).range == 1:12
    @test firstindex(residues) == 1
    @test lastindex(residues) == 104
    @test_throws ArgumentError residues[1]
    residues = collect(eachresidue(atoms))
    @test index.(filter(at -> name(at) in ("N", "HG1"), residues[2])) == [13, 21]
    @test findall(at -> name(at) in ("N", "HG1"), residues[2]) == [1, 9]
end

#
# io show functions
#
function Base.show(io::IO, ::MIME"text/plain", residue::Residue)
    println(io, " Residue of name $(name(residue)) with $(length(residue)) atoms.")
    print_short_atom_list(io, @view residue.atoms[residue.range])
end

function Base.show(io::IO, residues::EachResidue)
    print(io, " Iterator with $(length(residues)) residues.")
end

function Base.show(io::IO, ::MIME"text/plain", residues::AbstractVector{Residue})
    print(io, "   Array{Residue,1} with $(length(residues)) residues.")
end

#
# Properties of residues
#
isprotein(residue::Residue) = haskey(protein_residues, resname(residue))

export isprotein
export isacidic, isaliphatic, isaromatic, isbasic, ischarged
export ishydrophobic, isneutral, isnonpolar, ispolar
export iswater

isacidic(r::Residue) = isprotein(r) && protein_residues[r.resname].type == "Acidic"
isaliphatic(r::Residue) = isprotein(r) && protein_residues[r.resname].type == "Aliphatic"
isaromatic(r::Residue) = isprotein(r) && protein_residues[r.resname].type == "Aromatic"
isbasic(r::Residue) = isprotein(r) && protein_residues[r.resname].type == "Basic"
ischarged(r::Residue) = isprotein(r) && protein_residues[r.resname].charge != 0
isneutral(r::Residue) = isprotein(r) && protein_residues[r.resname].charge == 0
ishydrophobic(r::Residue) = isprotein(r) && protein_residues[r.resname].hydrophobic
ispolar(r::Residue) = isprotein(r) && protein_residues[r.resname].polar
isnonpolar(r::Residue) = isprotein(r) && !ispolar(r)

isacidic(atom::Atom) = isprotein(atom) && protein_residues[atom.resname].type == "Acidic"
isaliphatic(atom::Atom) = isprotein(atom) && protein_residues[atom.resname].type == "Aliphatic"
isaromatic(atom::Atom) = isprotein(atom) && protein_residues[atom.resname].type == "Aromatic"
isbasic(atom::Atom) = isprotein(atom) && protein_residues[atom.resname].type == "Basic"
ischarged(atom::Atom) = isprotein(atom) && protein_residues[atom.resname].charge != 0
isneutral(atom::Atom) = isprotein(atom) && protein_residues[atom.resname].charge == 0
ishydrophobic(atom::Atom) = isprotein(atom) && protein_residues[atom.resname].hydrophobic
ispolar(atom::Atom) = isprotein(atom) && protein_residues[atom.resname].polar
isnonpolar(atom::Atom) = isprotein(atom) && !ispolar(atom)

const water_residues = ["HOH", "OH2", "TIP3", "TIP3P", "TIP4P", "TIP5P", "TIP7P", "SPC", "SPCE"]
iswater(r::Residue; water_residues=water_residues) = r.resname in water_residues
iswater(atom::Atom; water_residues=water_residues) = atom.resname in water_residues

@testitem "residue of atom" begin
    pdb = readPDB(PDBTools.TESTPDB)
    glu = select(pdb, "resname GLU")
    @test isacidic(glu[1])
    @test !isaliphatic(glu[1])
    @test !isaromatic(glu[1])
    @test !isbasic(glu[1])
    @test ischarged(glu[1])
    @test !isneutral(glu[1])
    @test !ishydrophobic(glu[1])
    @test ispolar(glu[1])
    @test !isnonpolar(glu[1])
    @test !iswater(glu[1])
    phe = select(pdb, "resname PHE")
    @test !isacidic(phe[1])
    @test !isaliphatic(phe[1])
    @test isaromatic(phe[1])
    @test !isbasic(phe[1])
    @test !ischarged(phe[1])
    @test isneutral(phe[1])
    @test ishydrophobic(phe[1])
    @test !ispolar(phe[1])
    @test isnonpolar(phe[1])
    @test !iswater(glu[1])
    wat = select(pdb, "water")
    @test iswater(wat[1])
end

@testitem "full residue" begin
    pdb = readPDB(PDBTools.TESTPDB)
    glu_atoms = select(pdb, "resname GLU")
    glu = collect(eachresidue(glu_atoms))
    @test isacidic(glu[1])
    @test !isaliphatic(glu[1])
    @test !isaromatic(glu[1])
    @test !isbasic(glu[1])
    @test ischarged(glu[1])
    @test !isneutral(glu[1])
    @test !ishydrophobic(glu[1])
    @test ispolar(glu[1])
    @test !isnonpolar(glu[1])
    @test !iswater(glu[1])
    phe_atoms = select(pdb, "resname PHE")
    phe = collect(eachresidue(phe_atoms))
    @test !isacidic(phe[1])
    @test !isaliphatic(phe[1])
    @test isaromatic(phe[1])
    @test !isbasic(phe[1])
    @test !ischarged(phe[1])
    @test isneutral(phe[1])
    @test ishydrophobic(phe[1])
    @test !ispolar(phe[1])
    @test isnonpolar(phe[1])
    @test !iswater(glu[1])
    wat = select(pdb, "water")
    @test iswater(wat[1])
end

"""
    residue_ticks(
        atoms (or) residues (or) residue iterator; 
        first=nothing, last=nothing, stride=1, oneletter=true, serial=false
    )

Returns a tuple with residue numbers and residue names for the given atoms, to be used as tick labels in plots.

The structure data can be provided a vector of `Atom`s, a vector of `Residue`s or an `EachResidue` iterator. 

`first` and `last` optional keyword parameters are integers that refer to the residue numbers to be included. 
The `stride` option can be used to skip residues and declutter the tick labels.

If `oneletter` is `false`, three-letter residue codes are returned. Residues with unknown names will be 
named `X` or `XXX`. 

If `serial=true` the sequential residue index will be used as the index of the ticks, instead
of the residue numbers.

# Examples

```jldoctest
julia> using PDBTools

julia> atoms = wget("1UBQ", "protein");

julia> residue_ticks(atoms; stride=10) # Vector{Atom} as input
([1, 11, 21, 31, 41, 51, 61, 71], ["M1", "K11", "D21", "Q31", "Q41", "E51", "I61", "L71"])

julia> residue_ticks(atoms; first=10, last=15, serial=true) # first=10 and serial indexing
([1, 2, 3, 4, 5, 6], ["G10", "K11", "T12", "I13", "T14", "L15"])

julia> residue_ticks(eachresidue(atoms); stride=10) # residue iterator as input
([1, 11, 21, 31, 41, 51, 61, 71], ["M1", "K11", "D21", "Q31", "Q41", "E51", "I61", "L71"])

julia> residue_ticks(collect(eachresidue(atoms)); stride=10) # Vector{Residue} as input
([1, 11, 21, 31, 41, 51, 61, 71], ["M1", "K11", "D21", "Q31", "Q41", "E51", "I61", "L71"])
```

The resulting tuple of residue numbers and labels can be used as `xticks` in `Plots.plot`, for example.

"""
function residue_ticks(residues::Union{AbstractVector{Residue},EachResidue};
    first=nothing, last=nothing, stride=1,
    oneletter::Bool = true,
    serial::Bool=false,
)
    resnames = resname.(residues)
    if oneletter
        resnames = PDBTools.oneletter.(resnames)
    end
    resnums = resnum.(residues)
    ticklabels = resnames .* string.(resnums)
    first = isnothing(first) ? 1 : findfirst(==(first), resnums)
    last = isnothing(last) ? length(residues) : findfirst(==(last), resnums)
    ticks = if serial
        (collect(1:stride:last-first+1), ticklabels[first:stride:last])
    else
        (resnums[first:stride:last], ticklabels[first:stride:last])
    end
    return ticks
end
function residue_ticks(atoms::AbstractVector{<:Atom}; kargs...)
    residues = eachresidue(atoms)
    return residue_ticks(residues; kargs...)
end

@testitem "residue_ticks" begin
    # residue indices start with 1
    atoms = wget("1UBQ")
    @test residue_ticks(eachresidue(atoms), stride=20) == ([1, 21, 41, 61, 81, 101, 121], ["M1", "D21", "Q41", "I61", "X81", "X101", "X121"])
    @test residue_ticks(collect(eachresidue(atoms)), stride=20) == ([1, 21, 41, 61, 81, 101, 121], ["M1", "D21", "Q41", "I61", "X81", "X101", "X121"])
    @test residue_ticks(atoms, stride=20) == ([1, 21, 41, 61, 81, 101, 121], ["M1", "D21", "Q41", "I61", "X81", "X101", "X121"])
    atoms = select(atoms, "protein")
    @test residue_ticks(atoms; stride=20) == ([1, 21, 41, 61], ["M1", "D21", "Q41", "I61"])
    @test residue_ticks(atoms; stride = 20, first = 2) == ([2, 22, 42, 62], ["Q2", "T22", "R42", "Q62"])
    @test residue_ticks(atoms; stride = 20, last = 42) == ([1, 21, 41], ["M1", "D21", "Q41"])
    @test residue_ticks(atoms; stride = 20, last = 42, first = 2) == ([2, 22, 42], ["Q2", "T22", "R42"])
    # serial indexing
    @test residue_ticks(atoms; first=10, stride=10, serial=true) == ([1, 11, 21, 31, 41, 51, 61], ["G10", "S20", "I30", "Q40", "L50", "N60", "V70"])
    @test residue_ticks(atoms; first=1, stride=10, serial=true) == ([1, 11, 21, 31, 41, 51, 61, 71], ["M1", "K11", "D21", "Q31", "Q41", "E51", "I61", "L71"])
    @test residue_ticks(atoms; first=1, stride=10, serial=true) == ([1, 11, 21, 31, 41, 51, 61, 71], ["M1", "K11", "D21", "Q31", "Q41", "E51", "I61", "L71"])
    @test residue_ticks(atoms; first=10, stride=1, last=15, serial=true) == ([1, 2, 3, 4, 5, 6], ["G10", "K11", "T12", "I13", "T14", "L15"])
    @test residue_ticks(atoms; first=10, stride=2, last=15, serial=true) == ([1, 3, 5], ["G10", "T12", "T14"])
    # Shift resnums
    for at in atoms
        at.resnum += 10
    end
    @test residue_ticks(atoms; stride=20) == ([1, 21, 41, 61], ["M11", "D31", "Q51", "I71"])
    @test residue_ticks(atoms; stride = 20, first = 2) == ([12, 32, 52, 72], ["Q12", "T32", "R52", "Q72"])
    @test residue_ticks(atoms; stride = 20, last = 42) == ([11, 31, 51], ["M11", "D31", "Q51"])
    @test residue_ticks(atoms; stride = 20, last = 42, first = 2) == 
    # serial indexing
    @test residue_ticks(atoms; first=10, stride=10, serial=true) == ([1, 11, 21, 31, 41, 51, 61], ["G10", "S20", "I30", "Q40", "L50", "N60", "V70"])
    @test residue_ticks(atoms; first=1, stride=10, serial=true) == ([1, 11, 21, 31, 41, 51, 61, 71], ["M1", "K11", "D21", "Q31", "Q41", "E51", "I61", "L71"])
    @test residue_ticks(atoms; first=1, stride=10, serial=true) == ([1, 11, 21, 31, 41, 51, 61, 71], ["M1", "K11", "D21", "Q31", "Q41", "E51", "I61", "L71"])
    @test residue_ticks(atoms; first=10, stride=1, last=15, serial=true) == ([1, 2, 3, 4, 5, 6], ["G10", "K11", "T12", "I13", "T14", "L15"])
    @test residue_ticks(atoms; first=10, stride=2, last=15, serial=true) == ([1, 3, 5], ["G10", "T12", "T14"])
    # residue indices do not start with 1
    atoms = wget("1LBD", "protein")
    @test residue_ticks(atoms, stride=38) == ([225, 263, 301, 339, 377, 415, 453], ["S225", "D263", "L301", "S339", "N377", "F415", "E453"])
    @test residue_ticks(atoms; stride=1, first = 227, last = 231) == ([227, 228, 229, 230, 231], ["N227", "E228", "D229", "M230", "P231"])
    @test residue_ticks(atoms; stride=2, first = 227, last = 231) == ([227, 229, 231], ["N227", "D229", "P231"])
    # three-letter return codes
    @test residue_ticks(atoms; stride=2, first = 227, last = 231, oneletter = false) == ([227, 229, 231], ["ASN227", "ASP229", "PRO231"])
end