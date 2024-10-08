#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_INIT(MCT, 2.0)

# PROCESS THE FOLLOWING MAKEFILES

AC_CONFIG_FILES(Makefile.conf)

# DECLARE PACKAGE OPTIONS

AC_ARG_ENABLE(mpiserial,
AC_HELP_STRING([--enable-mpiserial],
[Use the included MPI replacement library for single processor]),
[DONOTCHECKMPI="DONOTCHECKMPI"]
)

AC_ARG_ENABLE(selectedrealkind,
AC_HELP_STRING([--enable-selectedrealkind],
[define single precision and double precision numbers using the selected_real_kind function. Default uses the kind inquiry function.]),
[SRKDEF="SELECTEDREALKIND"]
)

AC_ARG_ENABLE(sequence,
AC_HELP_STRING([--enable-sequence],[Modify MCT types to make them contiguous in memory.]),
[SRKDEF="SEQUENCE"],)

AC_ARG_ENABLE(babel,
AC_HELP_STRING([--enable-babel],[Supply this option if you plan on building the Babel bindings to MCT]),
[SRKDEF="SEQUENCE"],)



# DECLARE THE FOLLOWING PRECIOUS VARIABLES

AC_ARG_VAR(MPILIBS,[MPI library command line invocation])
AC_ARG_VAR(MPIHEADER,[MPI header include path with INCLUDEFLAG])
AC_ARG_VAR(FPP,C-preprocessor for Fortran source code)
AC_ARG_VAR(FPPFLAGS,C-preprocessing flags for Fortran source code)
AC_ARG_VAR(MACHDEFS,MCT compiler and OS flags)
AC_ARG_VAR(FC,The Fortran compiler)
AC_ARG_VAR(FCFLAGS,User-defined Fortran compiler flags)
AC_ARG_VAR(ALLCFLAGS,Customized C source compilation flags)
AC_ARG_VAR(OPT,Fortran compiler flag for optimization level) 
AC_ARG_VAR(REAL8,[Fortran compiler flag for setting the default REAL size to REAL(KIND=8)])
AC_ARG_VAR(BIT64,Fortran compiler flag for generating 64-bit objects)
AC_ARG_VAR(ENDIAN,Fortran compiler flag for converting big-endian to little-endian)
AC_ARG_VAR(INCLUDEFLAG,Fortran compiler flag for specifying module search path)
AC_ARG_VAR(INCLUDEPATH,Additional library and module paths with INCLUDEFLAG)
AC_ARG_VAR(AR,Archive command)
AC_ARG_VAR(BABELROOT,Root directory of your Babel installation. i.e.: $BABELROOT/bin/babel $BABELROOT/lib/libsidl.so)
AC_ARG_VAR(COMPILER_ROOT,Root directory of your (F90) compiler)
AC_ARG_VAR(FORT_SIZE, Number of bits in Fortran real and double kind)

# INCLUDE BABELROOT and COMPILER_ROOT in Makefile.conf(autoconf output)
AC_SUBST(BABELROOT)
AC_SUBST(COMPILER_ROOT)
AC_SUBST(PYTHON)
AC_SUBST(PYTHONOPTS)

# SET TEMPORARY VARIABLES

# OS AND PLATFORM NAME
test "$osname"=NONE && osname=`uname -s`
test "$machinename"=NONE && machinename=`uname -m`
fullhostname=`hostname -f`


# HARDCODE SPECIFIC MACHINES FOR EXTRAORDINARY CIRCUMSTANCES

# CHECK IF WE ARE ON THE EARTH SIMULATOR
ES="NO"
if echo $osname | grep -i esos >/dev/null 2>&1; then
   ES="YES"
fi
if echo $osname | grep -i hp-ux >/dev/null 2>&1; then   
   if test "$ac_hostname" = "moon"; then 
      ES="YES"
      # TELLS CONFIGURE NOT TO RUN ANY TESTS THAT REQUIRE EXECUTION
      cross_compiling="yes"
   fi
fi
if test "$ES" = "YES"; then   
   echo "Using preset configuration values for the Earth Simulator"
   if test -z "$CC"; then
      CC="escc"
   fi
   if test -z "$F90"; then
      F90="esf90"
   fi
   if test -z "$MPIF90"; then
      MPIF90="esmpif90"
   fi
   if test -z "$AR"; then
      AR="esar cqs"
   fi
   if test -z "FPP"; then
      FPPFLAGS=" "
   fi
   if test -z "$F90FLAGS"; then
      F90FLAGS="-EP -Wf'-pvctl fullmsg -L fmtlist transform map'"
   fi
   if test -z "$OPT"; then
      OPT="-C vopt"
   fi      
   if test -z "$MACHDEFS"; then
      MACHDEFS="-DESVEC"
   fi
fi

# CHECK IF WE ARE ON THE NCSA IA-64 CLUSTER TITAN
if test "$ac_hostname" = "user02"; then
   if echo $osname | grep -i linux >/dev/null 2>&1; then
      if test -z "$MPILIBS"; then
         if test -z "$MPIHEADER"; then
            echo "Using preset MPI configuration for titan"
	    MPILIBS="-L/usr/local/vmi/mpich/lib/intel -lmpich -lvmi -ldl -lpthread"
	    MPIHEADER="-I/usr/local/vmi/mpich/include"
         fi
      fi
   fi
fi


# Check if we are on the ANL BG/P

if echo $fullhostname | egrep -q '.\.(surveyor|intrepid)\.alcf\.anl\.gov' 
  then if test -z "$FC"; then
         FC=mpixlf90_r
       fi
       if test -z "$CC"; then
         CC=mpixlc_r
       fi
fi



# START TESTS

# CHECK FOR THE C COMPILER
AC_PROG_CC([cc])

# CHECK FOR THE FORTRAN COMPILER
AC_PROG_F90

# CHECK FOR MPI LIBRARIES
AC_LANG_PUSH(Fortran 90)

OLDF90FLAGS="$F90FLAGS"

if test -n "$MPIHEADER"; then
   F90FLAGS="$F90FLAGS $MPIHEADER"
fi

# CHECK MPI BY DEFAULT
if test -z "$DONOTCHECKMPI"; then
   ACX_MPI
fi

# DONT CHECK MPI IF SERIALMPI OPTION IS ENABLED
if test -n "$DONOTCHECKMPI"; then
   echo "MPISERIAL ENABLED: BYPASSING MPI CHECK"
   if test -z "$MPIF90"; then
      MPIF90=$F90
   fi
   if test -z "$FORT_SIZE"; then
      FORT_SIZE="real4double8"
      echo "FORT_SIZE IS PRESET TO $FORT_SIZE"
   fi   
   abs_top_builddir=`pwd`
   MPISERPATH=$abs_top_builddir/mpi-serial
   AC_SUBST(MPISERPATH)
   MPIHEADER=-I$MPISERPATH
   MPILIBS="-L$MPISERPATH -lmpi-serial"
fi

F90FLAGS="$OLDF90FLAGS"

# A HACK TO FIX ACX_MPI TO GET MPILIBS TO BE AN EMPTY STRING
if test "$MPILIBS" = " "; then
   MPILIBS=""
fi

# SET FC TO MPIF90. IF MPILIBS IS PRESENT, SET FC TO F90.
if test -z "$FC"; then
   FC=$MPIF90
   if test "$F90" != "$MPIF90";  then
      if test -n "$MPILIBS"; then
	 FC=$F90
      fi
   fi
fi

# FOR SANITY, CHECK THAT FILENAME EXTENSION FOR FC IS CONSISTENT WITH F90
OLDF90="$F90"
F90="$FC"

AC_COMPILE_IFELSE(
  [subroutine oof(); return; end], [],
  [AC_MSG_WARN([$FC FAILED TO COMPILE FILENAME EXTENSION $ac_ext])
  ])

F90="$OLDF90"

# CHECK HOW TO GET THE COMPILER VERSION.
# THIS TEST DOES NOT WORK FOR XLF COMPILERS.
if test "$F90" != "xlf90"; then
   _AC_PROG_F90_VERSION
fi
f90_version="$ac_f90_version_output"

AC_LANG_POP(Fortran 90)

# CHECK FOR BYTE ORDERING
AC_C_BIGENDIAN

# CHECK IF FORTRAN COMPILER CREATES MODULE FILES IN UPPERCASE OR LOWERCASE
OLDF90="$F90"
OLDF90FLAGS="$F90FLAGS"

F90="$FC" # use MPIF90, since differences may exist between MPIF90 and F90 
if test "$F90" = "frt"; then # -Am flag needed for frt to gerate mod files
   F90FLAGS="$F90FLAGS -Am"
fi
if test "$F90" = "ftn"; then # -em flag needed for ftn to gerate mod files
   F90FLAGS="$F90FLAGS -em"
fi
if test "$F90" = "mpif90"; then
   F90FLAGS="$F90FLAGS"
fi

AC_F90_MOD_UPPERCASE

F90="$OLDF90"
F90FLAGS="$OLDF90FLAGS"

# CHECK HOW TO NAME MANGLE C FUNCTIONS SO THAT IT CAN BE CALLED FROM FORTRAN
OLDF90="$F90"
F90="$FC" # use MPIF90, since differences may exist between MPIF90 and F90

AC_F90_C_NAME_MANGLING

case $ac_cv_f90_mangling in
  "lower case, underscore") 
	 name_mangling="FORTRAN_UNDERSCORE_";;
  "lower case, no underscore")
	 name_mangling="FORTRAN_SAME";;
  "upper case, no underscore")  
	 name_mangling="FORTRAN_CAPS_";;
  "lower case, double underscore") 
	 name_mangling="FORTRAN_GNUF2C";;
  *) 
         name_mangling="FORTRAN_MANGLING_UNKNOWN" 
	 AC_MSG_WARN([UNKNOWN FORTRAN 90 NAME-MANGLING SCHEME]);;
esac

F90="$OLDF90"

# FPP AND FPPFLAGS ARE HARDCODED AS A LAST RESORT:
# DO NOT USE THE GNU C PREPROCESESSOR- 
# IT DOES NOT PROCESS FORTRAN SOURCES CORRECTLY.
# LOOK FOR MACHINE DEPENDENT CPP.
# THE HARCODED FPPFLAGS WORKS WITH MOST CPP COMMANDS.
if test -z "$FPP"; then
   AC_CHECK_PROGS(FPP,[cpp],$CPP)
fi
if test -z "$FPPFLAGS"; then
   FPPFLAGS="-P -C -N -traditional"
fi

# CHECK THAT THE FORTRAN COMPILER CAN CORRECTLY PROCESS THESE DIRECTIVES
# IF NOT, USE THE EXTERNAL C PREPROCESSOR
OLDF90="$F90"
F90="$FC" # use MPIF90, since differences may exist between MPIF90 and F90

defineflag="-Daardvark"
if test "$OLDF90" = "xlf90"; then
   defineflag="-WF,-Daardvark"
fi   
if test "$OLDF90" = "frt"; then
   defineflag="-Wp,-Daardvark"
fi

AC_CHECK_FPP_COMPILER(
[
  implicit none
#if zebra || aardvark
  character(len=25) :: ch  ! '
#endif
  ch="Does this test &
!Comment-Line
          &work? "// &
          "YES!"
], [$defineflag])

if test -n "$FPP"; then

defineflag="-Daardvark"

AC_CHECK_FPP_EXTERNAL(
[
  implicit none
#if zebra || aardvark
  character(len=25) :: ch  ! '
#endif
  ch="Does this test &
!Comment-Line
          &work? "// &
          "YES!"
], [$defineflag])

fi

F90="$OLDF90"

# ACTIVATE F90RULE IF FORTRAN COMPILER SUCCEEDS AT PREPROCESSING
# ACTIVATE F90RULECPP IF FOTRAN COMPILER FAILS AT PREPROCESSING
if test "$ac_cv_f90_fpp_compiler" = "yes"; then
   AC_SUBST(F90RULE,[.F90.o])
   AC_SUBST(F90RULECPP,[.F90RULECPP])
fi

if test "$ac_cv_f90_fpp_compiler" = "no"; then
if test "$ac_cv_f90_fpp_external" = "no"; then
   AC_MSG_WARN([FORTRAN SOURCE PREPROCESSING HAS FAILED])
   if test -z "$FPP"; then
      AC_MSG_WARN([TRY DEFINING CPP PATH IN CONFIGURE INVOCATION])
   fi
fi
if test "$ac_cv_f90_fpp_external" = "yes"; then
   AC_SUBST(F90RULE,[.F90RULE])
   AC_SUBST(F90RULECPP,[.F90.o])
fi
fi

# DEFINE VARIABLES ACCORDING TO OS AND COMPILER

echo "Hostname=$ac_hostname"
echo "Machine=$machinename"
echo "OS=$osname"

# CHECK OS NAME
if echo $osname | grep -i aix >/dev/null 2>&1; then
   SYSDEF="AIX"
fi
if echo $osname | grep -i darwin >/dev/null 2>&1; then
   SYSDEF="DARWIN"
fi
if echo $osname | grep -i unix_system_v >/dev/null 2>&1; then
   SYSDEF="UNIXSYSTEMV"
fi
if echo $osname | grep -i irix >/dev/null 2>&1; then
   SYSDEF="IRIX"
fi
if echo $osname | grep -i irix64 >/dev/null 2>&1; then
   SYSDEF="IRIX64"
fi
if echo $osname | grep -i linux >/dev/null 2>&1; then
   SYSDEF="LINUX"
fi
if echo $osname | grep -i osf1 >/dev/null 2>&1; then
   SYSDEF="OSF1"
fi
if echo $osname | grep -i super >/dev/null 2>&1; then
   SYSDEF="SUPERUX"
fi
if echo $osname | grep -i sun >/dev/null 2>&1; then
   SYSDEF="SUNOS"
fi
if echo $osname | grep -i t3e >/dev/null 2>&1; then
   SYSDEF="T3E"
fi
if echo $osname | grep -i unicos >/dev/null 2>&1; then
   SYSDEF="UNICOS"
fi
if test -z "$SYSDEF"; then
   AC_MSG_WARN([OPERATING SYSTEM UNKNOWN])
   SYSDEF="UNKNOWNOS"
fi

# CHECK COMPILER NAME
if echo $F90 | grep xlf90 >/dev/null 2>&1; then
   echo "Fortran Compiler is XLF"
   CPRDEF="XLF"
   if test -z "$REAL8"; then
      REAL8="-qrealsize=8"
   fi
   if test -z "$OPT"; then
      OPT="-O2"
   fi
   if test -z "$F90FLAGS"; then
      if test "$ac_cv_f90_fpp_compiler" = "yes"; then
         F90FLAGS="-qarch=auto -qsuffix=f=F90:cpp=F90"
      fi
      if test "$ac_cv_f90_fpp_compiler" = "no"; then
         if test "$ac_cv_f90_fpp_external" = "yes"; then
	    F90FLAGS="-qarch=auto -qsuffix=f=f90"
         fi
      fi
   fi
fi

if echo $F90 | grep pgf90 >/dev/null 2>&1; then
   echo "Fortran Compiler is Portland Group"
   CPRDEF="PGI"
   if test -z "$REAL8"; then
      REAL8="-r8"
   fi
   if test -z "$BIT64"; then
      BIT64="-pc 64"
   fi
   if test -z "$ENDIAN"; then
      ENDIAN="-byteswapio"
   fi
   if test -z "$OPT"; then
      OPT="-O2"
   fi
fi

if echo $F90 | grep ftn >/dev/null 2>&1; then
 if echo $f90_version | grep -i Portland >/dev/null 2>&1; then
   echo "Fortran Compiler is Portland Group, XT3"
   CPRDEF="PGI"
   SYSDEF="CATAMOUNT"
   if test -z "$REAL8"; then
      REAL8="-r8"
   fi
   if test -z "$BIT64"; then
      BIT64="-pc 64"
   fi
   if test -z "$ENDIAN"; then
      ENDIAN="-byteswapio"
   fi
   if test -z "$OPT"; then
      OPT="-O2"
   fi
 elif echo $f90_version | grep -i Intel >/dev/null 2>&1; then
   echo "Fortran Compiler is Intel Group, XT3"
   CPRDEF="INTEL"
   SYSDEF="CATAMOUNT"
   if test -z "$REAL8"; then
      REAL8="-r8"
   fi
   if test -z "$F90FLAGS"; then
      F90FLAGS="-w -ftz -assume byterecl"
   fi
   if test -z "$ENDIAN"; then
      ENDIAN="-convert big_endian"
   fi
   if test -z "$OPT"; then
      OPT="-O2"
   fi
 else
   echo "Fortran Compiler is Cray"
   CPRDEF="CRAY" 
   if test -z "$F90FLAGS"; then 
      F90FLAGS="-c -em -dy -rm -Omsgs,negmsgs"
   fi
   if test -z "$INCLUDEFLAG"; then
      INCLUDEFLAG="-p"
   fi
   if test -z "$OPT"; then
      OPT="-Oscalar3 -Ovector1 -Ostream1"
   fi
 fi
fi

if echo $F90 | grep frt >/dev/null 2>&1; then
   echo "Fortran Compiler is UXP/V"
   echo "Suggested additional vectorization flags: -Wv,-s5,-t3,-noalias,-ilfunc,-md"
   CPRDEF="FUJITSU"
   if test -z "$F90FLAGS"; then
      F90FLAGS="-Am -X9"
   fi
   if test -z "$BIT64"; then
      BIT64="-KA64"
   fi
   if test -z "$REAL8"; then
      REAL8="-Ad"
   fi
fi

if echo $F90 | grep epcf90 >/dev/null 2>&1; then
   echo "Everest has never tested the epcf90 compiler :("
   CPRDEF="EPC"
fi

if echo $F90 | grep lf95 >/dev/null 2>&1; then
   echo "Fortran Compiler is Lahey"
   CPRDEF="LAHEY"
fi

if echo $F90 | grep ifc >/dev/null 2>&1; then
   echo "Fortran Compiler is Intel 7.x or earlier"
   echo "Intel ifc compiler must set the environment variable F_UFMTENDIAN=big to do endian conversion"
   CPRDEF="INTEL"
   if test -z "$REAL8"; then
      REAL8="-r8"
   fi
   if test -z "$F90FLAGS"; then
      F90FLAGS="-w"
   fi
   if test -z "$OPT"; then
      OPT="-O2"
   fi
fi

if echo $F90 | grep efc >/dev/null 2>&1; then
   echo "Fortran Compiler is Intel 7.x or earlier for IA-64"
   echo "Intel efc compiler must set the environment variable F_UFMTENDIAN=big to do endian conversion"
   CPRDEF="INTEL"
   if test -z "$REAL8"; then
      REAL8="-r8"
   fi
   if test -z "$F90FLAGS"; then
      F90FLAGS="-w -ftz"
   fi
   if test -z "$OPT"; then
      OPT="-O2"
   fi
fi

if echo $F90 | grep ifort >/dev/null 2>&1; then
   echo "Fortran Compiler is Intel ifort"
   CPRDEF="INTEL"
   if test -z "$REAL8"; then
      REAL8="-r8"
   fi
   if test -z "$F90FLAGS"; then
      F90FLAGS="-w -ftz -assume byterecl"
   fi
   if test -z "$ENDIAN"; then
      ENDIAN="-convert big_endian"
   fi
   if test -z "$OPT"; then
      OPT="-O2"
   fi
fi

if echo $F90 | grep pathf90 >/dev/null 2>&1; then
   echo "Fortran Compiler is PathScale"
   CPRDEF="PATHSC"
   if test -z "$REAL8"; then
      REAL8="-r8"
   fi
   if test -z "$BIT64"; then
      BIT64="-m64"
   fi
   if test -z "$OPT"; then
      OPT="-O2"
   fi
fi

if echo $F90 | grep g95 >/dev/null 2>&1; then
   echo "Fortran Compiler is GNU"
   CPRDEF="GNU"
fi

if echo $F90 | grep gfortran >/dev/null 2>&1; then
   echo "Fortran Compiler is GNU"
   CPRDEF="GNU"
fi

if echo $f90_version | grep -i nag >/dev/null 2>&1; then
   echo "Fortran Compiler is NAG"
   CPRDEF="NAG"
   if test -z "$F90FLAGS"; then
      F90FLAGS="-dusty -kind=byte"
   fi
   if test -z "$OPT"; then
      OPT="-O2"
   fi
fi

if echo $f90_version | grep -i absoft >/dev/null 2>&1; then
   echo "Fortran Compiler is Absoft"
   CPRDEF="ABSOFT"
   if test -z "$REAL8"; then
      REAL8="-N113"
   fi    
   if test -z "$INCLUDEFLAG"; then
      INCLUDEFLAG="-p"
   fi
   if test -z "$OPT"; then
      OPT="-O2"
   fi
fi

if echo $f90_version | grep -i workshop >/dev/null 2>&1; then
   echo "Fortran Compiler is Workshop"
   CPRDEF="WORKSHOP"
   if test -z "$INCLUDEFLAG"; then
      INCLUDEFLAG="-M"
   fi
fi

if echo $f90_version | grep -i mipspro >/dev/null 2>&1; then
   echo "Fortran Compiler is MIPSPro"
   CPRDEF="MIPSPRO"
   EXTRACFLAGS="-64"
   if test -z "$OPT"; then
      OPT="-O3"
   fi
   if test -z "$REAL8"; then
      REAL8="-r8"
   fi
   if test -z "$BIT64"; then
      BIT64="-64"
   fi
fi

if echo $f90_version | grep -i compaq >/dev/null 2>&1; then
   echo "Fortran Compiler is Compaq"
   CPRDEF="COMPAQ"
   MPILIBS="$MPILIBS -lelan"
   if test -z "$OPT"; then
      OPT="-fast"
   fi
   if test -z "$REAL8"; then
      REAL8="-real_size 64"
   fi
   if test -z "$ENDIAN"; then
      ENDIAN="-convert big_endian"
   fi
fi

# Compaq Fortran changed its name to HP Fortran.
# Lets support both versions for now.
if echo $f90_version | grep HP >/dev/null 2>&1; then
   echo "Fortran Compiler is HP"
   CPRDEF="COMPAQ"
   MPILIBS="$MPILIBS -lelan"
   if test -z "$OPT"; then
      OPT="-fast"
   fi
   if test -z "$REAL8"; then
      REAL8="-real_size 64"
   fi
   if test -z "$ENDIAN"; then
      ENDIAN="-convert big_endian"
   fi
fi

if echo $f90_version | grep -i sx >/dev/null 2>&1; then
   echo "Fortran Compiler is SX"
   CPRDEF="SX"
   if test -z "$F90FLAGS"; then
      F90FLAGS="-EP -Wf'-pvctl noassoc'"
   fi
   if test -z "$OPT"; then
      OPT="-Chopt"
   fi
fi

if test -z "$CPRDEF"; then
   AC_MSG_WARN([UNKNOWN FORTRAN 90 COMPILER])
   CPRDEF="UNKNOWNCPR"
fi

# SET THE PREPROCESSOR DEFINE FLAGS
if test -z "$MACHDEFS"; then

   MACHDEFS="-DSYS$SYSDEF -DCPR$CPRDEF" # DEFAULT FLAGS
   if test -n "$SRKDEF"; then
      MACHDEFS="$MACHDEFS -D$SRKDEF"
   fi

   if test "$F90" = "xlf90"; then # SPECIAL XLF FLAGS
      if test "$ac_cv_f90_fpp_compiler" = "yes"; then
         MACHDEFS="-WF,-DSYS$SYSDEF,-DCPR$CPRDEF"
	 if test -n "$SRKDEF"; then
            MACHDEFS="$MACHDEFS,-D$SRKDEF"
         fi
      fi
   fi

   if test "$F90" = "frt"; then # SPECIAL FRT FLAGS
      if test "$ac_cv_f90_fpp_compiler" = "yes"; then
         MACHDEFS="-Wp,-DSYS$SYSDEF,-DCPR$CPRDEF"
         if test -n "$SRKDEF"; then
            MACHDEFS="$MACHDEFS,-D$SRKDEF"
         fi
      fi
   fi

fi

if test -z "$ALLCFLAGS"; then # SET C COMPILE FLAGS
   ALLCFLAGS="-D$name_mangling -DSYS$SYSDEF -DCPR$CPRDEF -O"
   if test -n "$EXTRACFLAGS"; then
      ALLCFLAGS="-D$name_mangling -O $EXTRACFLAGS"
   fi
fi

# SET HARDCODED VARIABLES AS A LAST RESORT

# ALWAYS ENABLE CRULE IN MAKEFILE
AC_SUBST(CRULE,[.c.o])

# INCLUDE FLAG IF NOT ALREADY SET IS MOST LIKELY -I
if test -z "$INCLUDEFLAG"; then
   INCLUDEFLAG="-I"
fi

# ARCHIVE COMMAND SIMILAR ACROSS ALL PLATFORMS 
if test -z "$AR"; then
   AR="ar cq"
fi

echo
echo Output Variables: {CC=$CC} {ALLCFLAGS=$ALLCFLAGS} \
{FPP=$FPP} {FPPFLAGS=$FPPFLAGS} {FC=$FC} \
{F90=$F90} {FCFLAGS=$FCFLAGS} {F90FLAGS=$F90FLAGS} \
{MACHDEFS=$MACHDEFS} {OPT=$OPT} {REAL8=$REAL8} \
{BIT64=$BIT64} {ENDIAN=$ENDIAN} {MPIF90=$MPIF90} \
{MPILIBS=$MPILIBS} {MPIHEADER=$MPIHEADER}  \
{INCLUDEFLAG=$INCLUDEFLAG} {INCLUDEPATH=$INCLUDEPATH} \
{AR=$AR} {BABELROOT=$BABELROOT} {COMPILER_ROOT=$COMPILER_ROOT} \
{PYTHON=$PYTHON} {PYTHONOPTS=$PYTHONOPTS} {FORT_SIZE=$FORT_SIZE} {prefix=$prefix}
echo

AC_OUTPUT

echo Please check the Makefile.conf
echo Have a nice day!

# test -z is true for empty strings
# test -n is true for non-empty strings




