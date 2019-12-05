#
# Reads PDB file atom data into a mutable array, such that the data can be edited
#

function editPDB(file :: String; chain :: String = "0", model :: Int64 = 0)

  pdb = readPDB(file, chain = chain, model = model)
  mutpdb = Vector{ReadAtom}(undef,length(pdb))
  @. mutpdb = ReadAtom(pdb)

end
