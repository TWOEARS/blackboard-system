function locErrors = calc_localisation_errors(srcLoc, estLocs)

locErrors = 180 - abs(abs(estLocs - srcLoc) - 180);
