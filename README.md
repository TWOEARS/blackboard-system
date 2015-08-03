Two!Ears Blackboard System
==========================

This is the development version of the Two!Ears Blackboard System, see
http://twoears.aipa.tu-berlin.de/doc/latest/blackboard/ for documentation on how
it works.

If you are interested in using the development version or contributing to its
code, have a look at
http://twoears.aipa.tu-berlin.de/doc/latest/dev/development-system/

## Installation

Normally everything should work out of the box if you are following [this
instruction](http://twoears.aipa.tu-berlin.de/doc/latest/dev/development-system/).
B
The LIBSVM Matlab package (http://www.csie.ntu.edu.tw/~cjlin/libsvm) is included in the 
third_pardy_software folder, with some changes and additions. This includes mex files for Win64
and Linux. 
However, for the case of Linux, the LIBSVM mex files provided in the third_pardy_software folder
might not work. In this case the libsvmpredict or libsvmtrain mex functions don't work, you need
to rebuild them for your system. Just go into third_party_software/libsvm-3.17/matlab folder and type
make.
