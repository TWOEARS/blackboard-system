
INSTALLATION

Add the functions to a folder, that is in your Matlab path, or add
the folder containing the functions to your Matlab path:
addpath('/path/to/ir_software');

USAGE

For a detailed description of the functions use the help command:
help read_irs
But for a first start try:
irs = read_irs('QU_KEMAR_anechoic_3m.mat');
ir = get_ir(irs,45);
figure; plot(ir(:,1),'-b',ir(:,2),'-r');

MAT-FILE FORMAT

The impulse responses are stored as a struct with the name irs in the mat-files.
To see what this struct contains, have a look at the mat-file format description 
at https://dev.qu.tu-berlin.de/projects/measurements/wiki/IRs_file_format.

