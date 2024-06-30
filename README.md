# FindScoreP

CMake integration for [Score-P](https://score-p.org).

## Usage

1. Place the files `FindScoreP.cmake` and `ScorePUtilities.cmake` somewhere in your
[`CMAKE_MODULE_PATH`](https://cmake.org/cmake/help/latest/variable/CMAKE_MODULE_PATH.html) and include `ScorePUtilities` in your CMake configuration.

2. Call `scorep_mark_instrumented` on targets which should be instrumented by Score-P.

3. After all targets have been defined call `scorep_required_components` and use its output
   to call [`find_package(ScoreP ...)`](https://cmake.org/cmake/help/latest/command/find_package.html).

4. Call `scorep_enable` to enable Score-P instrumentation.

  - it is advised to call `find_package(ScoreP)` and `scorep_enable` based on an option for a flexible build configuration 

### Functions

After including the `ScorePUtilities` module the following functions are available:

`scorep_instrument(target)`, which configures a target to be instrumented by Score-P and supports the following keywords:

 - `OVERRIDE`, an option that when enabled allows overwriting existing `<LANG>_COMPILER_LAUNCHER` and `<LANG>_LINKER_LAUNCHER` properties

 - `LANGS`, a multi-value keyword which lists the names of the languages to instrument

 - `ARGUMENTS`, a multi-value keyword which lists the commandline arguments to Score-P

 - `AUTO`, an option which enables automatic detection of the following arguments:

   - `--thread=omp`

   - `--thread=pthread`

   - `--mpp=mpi`

   - `--io=posix`

   - `--cuda`
   
   - `--openmp`

   - `--opencl`

   - `--openacc`

This function ignores the `SCOREP_LANGUAGES` and `SCOREP_ARGUMENTS` properties and is intended to be used through `scorep_enable`.

`scorep_mark_instrumented()`, which marks targets to be instrumented when calling `scorep_enable` and supports the following keywords:

 - `DIRECTORIES`, a multi-value keyword which lists directories in which all targets should be instrumented

 - `TARGETS`, a multi-value keyword which lists targets which should be instrumented

 - `LANGS`, a multi-value keyword which lists the names of the languages to instrument

 - `ARGUMENTS`, a multi-value keyword which lists the commandline arguments to Score-P

 - `AUTO`, an option which enables automatic detection of the following arguments:

   - `--thread=omp`

   - `--thread=pthread`

   - `--mpp=mpi`

   - `--io=posix`

   - `--cuda`
   
   - `--openmp`

   - `--opencl`

   - `--openacc`

   - `--kokkos`

   - `--hip`

The function defaults to the current directory if no directories or targets are passed
and does by itself nothing besides setting the `SCOREP_LANGUAGES` and `SCOREP_<LANG>_ARGUMENTS` properties.

`scorep_required_components(outVar)`, which stores the components required for the instrumentation of targets marked by `scorep_mark_instrumented` in outVar and supports the following keywords:

 - `DIRECTORIES`, a multi-value keyword which lists directories in which all targets should be checked

 - `TARGETS`, a multi-value keyword which lists targets which should be checked

The function defaults to the current directory if no directories or targets are passed.

`scorep_enable()`, which instruments targets marked by `scorep_mark_instrumented` and supports the following keywords:

 - `DIRECTORIES`, a multi-value keyword which lists directories in which all targets should be checked

 - `TARGETS`, a multi-value keyword which lists targets which should be checked

 - `OVERRIDE`, an option that when enabled allows overwriting existing `<LANG>_COMPILER_LAUNCHER` and `<LANG>_LINKER_LAUNCHER` properties

The function defaults to the current directory if no directories or targets are passed.

### Properties

The `ScorePUtilities` module uses or defines the following properties:

 - `SCOREP_LANGUAGES`, a target property which when contains all languages to be instrumented when calling `scorep_enable`.

 - `SCOREP_<LANG>_ARGUMENTS`, a target property which contains command line arguments to Score-P for instrumenting language LANG.

 - `SCOREP_LANGUAGES_<TARGET>`, a cache variable which may override the `SCOREP_LANGUAGES` property of a target.

 - `SCOREP_<LANG>_ARGUMENTS_<TARGET>`, a cache variable which may override the `SCOREP_<LANG>_ARGUMENTS` property of a target.

The cache variables are intended to be set by users who wish to override which and how targets are instrumented when calling `scorep_enable`.

### Examples

Examples for using these functions are located in the `examples` directory.


## Find Module

The find module `FindScoreP.cmake` can be used independently of any instrumentation infrastructure
while supporting multiple installed versions and version ranges.

### Components

`COMPILER_<LANGUAGE>_<PATH>`, representing the compiler suite used by Score-P.

Possible values for LANGUAGE:

 - C99

 - CXX11

 - Fortran

 - Fortran77

PATH contains the path to the requested compiler executable.

`MPI_COMPILER_<LANGUAGE>_<PATH>`, representing the MPI compiler suite used by Score-P.

Possible values for LANGUAGE:

 - C99

 - CXX11

 - Fortran

 - Fortran77

PATH contains the path to the requested compiler executable.

`SHMEM_COMPILER_<LANGUAGE>_<PATH>`, representing the SHMEM compiler suite used by Score-P.

Possible values for LANGUAGE:

 - C99

 - CXX11

 - Fortran

 - Fortran77

PATH contains the path to the requested compiler executable.

`PTHREADS`, representing pthread support.

`MPP_<PARADIGM>`, representing multi-process support.

Possible values for PARADIGM:

 - mpi

 - shmem

`IO_<PARADIGM>`, representing I/O recording support.

Possible values for PARADIGM:

 - posix

`COMPILER`, representing compiler instrumentation support.

`CUDA`, representing CUDA instrumentation support.

`POMP`, representing POMP user instrumentation support.

`OMP_<LANG>`, representing OpenMP language support.

Possible values for LANG:

 - C

 - CXX

 - Fortran

`OPARI2`, representing OPARI2 instrumentation support.

`OMPT`, representing OMPT instrumentation support.

`PDT`, representing PDT instrumentation support.

`OPENCL`, representing OpenCL support.

`OPENACC`, representing OpenACC support.

`MEMORY`, representing memory usage instrumentation support.

`LIBWRAP`, representing library wrapper support

`KOKKOS`, representing Kokkos support

`HIP`, representing HIP support.

### Imported Targets

`ScoreP::ScoreP`, the scorep executable.

`ScoreP::Config`, the scorep-config executable.

`ScoreP::Info`, the scorep-info executable.

### Result Variables

`SCOREP_FOUND`, True if a matching Score-P installation was found.

`SCOREP_<COMPONENT>_FOUND`, True if the component was found.

`SCOREP_EXECUTABLE`, the path of the scorep executable.

`SCOREP_CONFIG_EXECUTABLE`, the path of the scorep-config executable.

`SCOREP_INFO_EXECUTABLE`, the path of the scorep-info executable

`SCOREP_VERSION_STRING`, the version of Score-P found.

## Tests

Testing using the [CTest](https://cmake.org/cmake/help/latest/module/CTest.html)
module requires a POSIX compatible shell to be installed.

The following labels exist:

 - `cmake`, indicating a CMake-only test

 - `scorep`, indicating a test requiring Score-P (with supported components based on the other labels)

 - `c`, indicating a test requiring a C compiler

 - `openmp`, indicating a test requiring OpenMP

 - `pthread`, indicating a test requiring pthreads

 - `openacc`, indicating a test requiring OpenACC

 - `boost`, indicating a test requiring certain boost components

 - `examples`, indicating a test building code examples
