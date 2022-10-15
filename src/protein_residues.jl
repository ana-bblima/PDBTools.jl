#
# Data for natural protein residues
#

struct ProteinResidue
    name::String
    three_letter_code::String
    one_letter_code::String
    type::String
    polar::Bool
    hydrophobic::Bool
    mono_isotopic_mass::Float64
    mass::Float64
    charge::Int
end

protein_residues = Dict{String,ProteinResidue}(
    "ALA" => ProteinResidue("Alanine",       "ALA", "A", "Aliphatic",  false, false,  71.037114,  71.0779,  0),
    "ARG" => ProteinResidue("Arginine",      "ARG", "R", "Basic",      true,  false, 156.101111, 156.1857,  1),
    "ASN" => ProteinResidue("Asparagine",    "ASN", "N", "Amide",      true,  false, 114.042927, 114.1026,  0),
    "ASP" => ProteinResidue("Aspartic acid", "ASP", "D", "Acidic",     true,  false, 115.026943, 115.0874, -1),
    "CYS" => ProteinResidue("Cysteine",      "CYS", "C", "Sulfuric",   false, false, 103.009185, 103.1429,  0),
    "GLN" => ProteinResidue("Glutamine",     "GLN", "Q", "Amide",      true,  false, 128.058578, 128.1292,  0),
    "GLU" => ProteinResidue("Glutamic acid", "GLU", "E", "Acidic",     true,  false, 129.042593, 129.1140, -1),
    "GLY" => ProteinResidue("Glycine",       "GLY", "G", "Aliphatic",  false, false,  57.021464,  57.0513,  0),
    "HIS" => ProteinResidue("Histidine",     "HIS", "H", "Aromatic",   true,  false, 137.058912, 137.1393,  0), 
    "ILE" => ProteinResidue("Isoleucine",    "ILE", "I", "Aliphatic",  false, true,  113.084064, 113.1576,  0),
    "LEU" => ProteinResidue("Leucine",       "LEU", "L", "Aliphatic",  false, true,  113.084064, 113.1576,  0),
    "LYS" => ProteinResidue("Lysine",        "LYS", "K", "Basic",      true,  false, 128.094963, 128.1723,  1),
    "MET" => ProteinResidue("Methionine",    "MET", "M", "Sulfuric",   false, false, 131.040485, 131.1961,  0),
    "PHE" => ProteinResidue("Phenylalanine", "PHE", "F", "Aromatic",   false, true,  147.068414, 147.1739,  0),
    "PRO" => ProteinResidue("Proline",       "PRO", "P", "Cyclic",     false, false,  97.052764,  97.1152,  0),
    "SER" => ProteinResidue("Serine",        "SER", "S", "Hydroxylic", true,  false,  87.032028, 87.07730,  0),
    "THR" => ProteinResidue("Threonine",     "THR", "T", "Hydroxylic", true,  false, 101.047679, 101.1039,  0),
    "TRP" => ProteinResidue("Tryptophan",    "TRP", "W", "Aromatic",   false, true,  186.079313, 186.2099,  0),
    "TYR" => ProteinResidue("Tyrosine",      "TYR", "Y", "Aromatic",   true,  false, 163.063320, 163.1733,  0),
    "VAL" => ProteinResidue("Valine",        "VAL", "V", "Aliphatic",  false, true,   99.068414,  99.1311,  0),
    # Alternate protonation states for CHARMM and AMBER
    "ASPP" => ProteinResidue("Aspartic acid (protonated)", "ASP", "D", "Acidic", true,  false, 115.026943, 115.0874, 0),
    "GLUP" => ProteinResidue("Glutamic acid (protonated)", "GLU", "E", "Acidic", true,  false, 129.042593, 129.1140, 0),
    "HSD"  => ProteinResidue("Histidine (D)", "HIS", "H", "Aromatic",   true,  false, 137.058912, 137.1393,  0), 
    "HSE"  => ProteinResidue("Histidine (E)", "HIS", "H", "Aromatic",   true,  false, 137.058912, 137.1393,  0), 
    "HSP"  => ProteinResidue("Histidine (doubly protonated)", "HIS", "H", "Aromatic",   true,  false, 137.058912, 137.1393,  1), 
    "HID"  => ProteinResidue("Histidine (D)", "HIS", "H", "Aromatic",   true,  false, 137.058912, 137.1393,  0), 
    "HIE"  => ProteinResidue("Histidine (E)", "HIS", "H", "Aromatic",   true,  false, 137.058912, 137.1393,  0), 
    "HIP"  => ProteinResidue("Histidine (doubly protonated)", "HIS", "H", "Aromatic",   true,  false, 137.058912, 137.1393,  1), 
)

"""
```
threeletter(residue::String) 
```

Function to return the three-letter natural-amino acid residue code from the one-letter 
code or residue name. The function is case-insensitive.

# Examples

```julia-repl
julia> threeletter("A")
"ALA"

julia> threeletter("Aspartic acid")
"ASP"

julia> threeletter("HSD")
"HIS"
```

"""
function threeletter(residue::Union{String,Char})
    # Convert to String if Char
    code = uppercase("$residue")
    if code in keys(protein_residues)
        return protein_residues[code].three_letter_code
    end
    if length(code) == 1
        return findfirst(r -> r.one_letter_code == code, protein_residues)
    else
        return findfirst(r -> uppercase(r.name) == code, protein_residues)
    end
end

@testitem "threeletter" begin
    @test threeletter("ALA") == "ALA"
    @test threeletter("A") == "ALA"
    @test threeletter('A') == "ALA"
    @test threeletter("Alanine") == "ALA"
    @test threeletter("GLUP") == "GLU"
    @test threeletter("HSP") == "HIS"
    @test isnothing(threeletter("XXX"))
end

"""
    oneletter(residue::Union{String,Char})

Function to return a one-letter residue code from the three letter code or residue name. The function is case-insensitive.

### Examples

```julia-repl
julia> oneletter("ALA")
"A"

julia> oneletter("Glutamic acid")
"E"

```

"""
function oneletter(residue::Union{String,Char})
    code = resname("$residue")
    if haskey(protein_residues, code)
        return protein_residues[code].one_letter_code
    else
        return nothing
    end
end

@testitem "oneletter" begin
    @test oneletter("ALA") == "A"
    @test oneletter("A") == "A"
    @test oneletter('A') == "A"
    @test oneletter("Alanine") == "A"
    @test oneletter("GLUP") == "E"
    @test oneletter("HSP") == "H"
    @test isnothing(oneletter("XXX"))
end


"""
    resname(residue::Union{String,Char})

Returns the residue name, given the one-letter code or residue name. Differently from
`threeletter`, this function will return the force-field name if available in the list
of protein residues.

# Examples
```julia-repl
julia> resname("ALA")
"ALA"

julia> resname("GLUP")
"GLUP"
```
"""
function resname(residue::Union{String,Char})
    code = uppercase("$residue")
    if code in keys(protein_residues)
        return code
    else
        return threeletter(code)
    end
end

@testitem "resname" begin
    @test resname("ALA") == "ALA"
    @test resname("A") == "ALA"
    @test resname('A') == "ALA"
    @test resname("Alanine") == "ALA"
    @test resname("GLUP") == "GLUP"
    @test resname("HSP") == "HSP"
    @test isnothing(resname("XXX"))
end

"""
    residuename(residue::Union{String,Char})

Function to return the long residue name from other residue codes. The function is case-insensitive.

### Examples

```julia-repl
julia> residuename("A")
"Alanine"

julia> residuename("Glu")
"Glutamic Acid"

```

"""
function residuename(residue::Union{String,Char})
    code = resname(residue)
    if haskey(protein_residues, code)
        return protein_residues[code].name
    else
        return nothing
    end
end

@testitem "residuename" begin
    @test residuename("A") == "Alanine"
    @test residuename("GLUP") == "Glutamic acid (protonated)"
    @test residuename("Ala") == "Alanine"
end

"""

```
Sequence
```

Wrapper for strings, or vectors of chars, strings, or residue names, to dispatch on 
functions that operate on amino acid sequences.

# Example

```julia-repl
julia> seq = ["Alanine", "Glutamic acid", "Glycine"];

julia> mass(Sequence(seq))
257.2432

julia> seq = "AEG";

julia> mass(Sequence(seq))
257.2432
```

"""
struct Sequence{T}
    s::T
end

"""

```
mass(s::Sequence)
```

Returns the mass of a sequence of amino acids, given a `Sequence` struct type.

# Examples

```julia-repl
julia> seq = ["Alanine", "Glutamic acid", "Glycine"];

julia> mass(Sequence(seq))
257.2432

julia> seq = "AEG";

julia> mass(Sequence(seq))
257.2432

julia> seq = ["ALA", "GLU", "GLY"];

julia> mass(Sequence(seq))
257.2432
```

"""
function mass(s::Sequence)
    m = 0.0
    for aa in s.s
        rname = resname(aa)
        m += protein_residues[rname].mass
    end
    return m
end

@testitem "sequence mass" begin
    @test mass(Sequence("AEG")) == 257.2432
    @test mass(Sequence(["ALA", "GLU", "GLY"])) == 257.2432
    @test mass(Sequence(["A", "E", "G"])) == 257.2432
    @test mass(Sequence(['A', 'E', 'G'])) == 257.2432
    @test mass(Sequence(["Alanine", "Glutamic acid", "Glycine"])) == 257.2432
end