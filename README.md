# FindScoreP

CMake find module for [Score-P](https://score-p.org).

## Usage

Place the module somewhere in your [`CMAKE_MODULE_PATH`](https://cmake.org/cmake/help/latest/variable/CMAKE_MODULE_PATH.html) and use

```cmake
find_package(ScoreP)
```

The find module can handle multiple installed versions and version ranges.

### Components

`THREAD_<PARADIGM>`, representing thread support.

Possible values for PARADIGM:

 - omp

 - pthread

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

`PDT`, representing PDT instrumentation support.

`OPENCL`, representing OpenCL support.

`OPENACC`, representing OpenACC support.

`MEMORY`, representing memory usage instrumentation support.

`LIBWRAP`, representing library wrapper support

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
module requires Score-P and a POSIX compatible shell to be installed.