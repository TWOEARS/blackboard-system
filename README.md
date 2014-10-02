Two!Ears WP3
============

Here you find the software of the blackboard system: the base system classes and the knowledge sources.


Test
====
The most up-to-date script using the whole functionality is multi_scenario1.m 
in the scenarios git repository, "s1_ident_include" branch.


Install
=======

=== LocationKS:
NOTE: is this still necessary?? There seem to be binaries in the third_party_software folder.
* Get latest version of GMTK: wp3git/third_party_software
* If you don't have Cygwin installed:
** Get latest version of Cygwin: http://cygwin.com/setup-x86_64.exe
** Install Cygwin 
*** make sure to add the latest version of gcc during the installation process
*** note by Ivo: there seem to be more dependencies than on the newest gcc - installing the whole 'devel' package worked for me. (Clean up if you tried compiling before with an older version and failed!)
* Unpack @gmtk-1.0.1.tar.gz@ to your Cygwin home directory (typically @..\cygwin64\home\<name>\@)
* Run the Cygwin shell and switch to gmtk root directory
* Compile the GMTK binaries
./configure && make && make install
* If you haven't installed Cygwin in @c:\cygwin64@, open @..\toy_scenario_stage1_dev\gmtk\gmtkEngine.m@ in Matlab and manually change your Cygwin and GMTK working directories in the class constructor function (somewhere around lines 66 and 71). A more comfortable solution will be implemented soon.

=== IdentifyKS:
The LIBSVM Matlab package (http://www.csie.ntu.edu.tw/~cjlin/libsvm) is included in the 
third_pardy_software folder, with some changes and additions. This includes mex files for Win64
and Linux. However, for the case of Linux, those mex files might not work.
* In case you the libsvmpredict or libsvmtrain mex functions don't work, you need to rebuild them for 
your system. Just go into third_party_software/libsvm-3.17/matlab folder and make.
