#
# Return the coordinates of the atoms
#

struct MaxMinCoords
    xmin::Vector{Float64}
    xmax::Vector{Float64}
    xlength::Vector{Float64}
end

"""

```
maxmin(atoms::Vector{Atom}; selection)
```

Returns the maximum and minimum coordinates of an atom vector, and the length (maximum minus minimum) in each direction. 

### Example

```julia-repl
julia> protein = wget("1LBD");

julia> maxmin(protein)
 
 Minimum atom coordinates: xmin = [-29.301, 57.178, 45.668]
 Maximum atom coordinates: xmax = [47.147, 99.383, 86.886]
 Length in each direction: xlength = [76.448, 42.205, 41.217999999999996]

```

"""
function maxmin(atoms::AbstractVector{Atom}, selection::String)
    query = parse_query(selection)
    return maxmin(atoms, only = atom -> apply_query(query, atom))
end

function maxmin(atoms::AbstractVector{Atom}; only = all)
    xmin = [+Inf, +Inf, +Inf]
    xmax = zeros(3)
    for at in atoms
        if only(at)
            xmin .= (min(at.x, xmin[1]), min(at.y, xmin[2]), min(at.z, xmin[3]))
            xmax .= (max(at.x, xmax[1]), max(at.y, xmax[2]), max(at.z, xmax[3]))
        end
    end
    xlength = @. xmax - xmin
    return MaxMinCoords(xmin, xmax, xlength)
end

function Base.show(io::IO, m::MaxMinCoords)
    println(io, " ")
    println(io, " Minimum atom coordinates: xmin = ", m.xmin)
    println(io, " Maximum atom coordinates: xmax = ", m.xmax)
    println(io, " Length in each direction: xlength = ", m.xlength)
end
