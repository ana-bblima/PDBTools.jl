function ischarged(atom::Atom)
  iaa = which_natural_aminoacid(atom)
  if iaa == 0
    false
  else
    if natural_aminoacids[iaa].charge != 0
      true
    else
      false
    end
  end
end
