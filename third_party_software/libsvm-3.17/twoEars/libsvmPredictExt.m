function [pred ret dec] = libsvmPredictExt(y, x, model)
[pred acc dec] = libsvmpredict(y, x, model);
if model.Label(1) < 0;
  dec = dec * -1;
end
ret = validation_function(dec, y);
