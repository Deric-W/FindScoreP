# Autodetection

The [`ScorepUtilities`](UTILITIES.md) module allows to automatically detect arguments and components required for Score-P instrumentation.

Since [generator expressions](https://cmake.org/cmake/help/latest/manual/cmake-generator-expressions.7.html) are only evaluated during
build system generation the autodetection only considers one target at a time without its dependencies.

## Arguments

The following paragraphs list all automatically detected arguments and the conditions which trigger them.

Autodetection for each argument is disabled when a conflicting argument is already present.

### --thread=omp and --openmp

 - linking against [`OpenMP::OpenMP_<lang>`](https://cmake.org/cmake/help/latest/module/FindOpenMP.html#result-variables) with
   [`OpenMP_<lang>_FOUND`](https://cmake.org/cmake/help/latest/module/FindOpenMP.html#result-variables) defined

### --thread=omp:ompt

 - linking against [`Kokkos::kokkos`](https://kokkos.org/kokkos-core-wiki/building.html#kokkos-philosophy) with
   [`Kokkos_ENABLE_OPENMP`](https://kokkos.org/kokkos-core-wiki/keywords.html#backend-selection) defined

### --thread=pthread

 - linking against [`Threads::Threads`](https://cmake.org/cmake/help/latest/module/FindThreads.html#imported-targets) with
   [`CMAKE_USE_PTHREADS_INIT`](https://cmake.org/cmake/help/latest/module/FindThreads.html#result-variables) defined

### --mpp=mpi

 - linking against [`MPI::MPI_<lang>`](https://cmake.org/cmake/help/latest/module/FindMPI.html#variables-for-using-mpi) with
   [`MPI_<lang>_FOUND`](https://cmake.org/cmake/help/latest/module/FindMPI.html#variables-for-using-mpi) defined

### --io=posix

 - [`UNIX`](https://cmake.org/cmake/help/latest/variable/UNIX.html) is set to `True`

### --cuda

 - the instrumented language is `CUDA`

 - linking against [`Kokkos::kokkos`](https://kokkos.org/kokkos-core-wiki/building.html#kokkos-philosophy) with
   [`Kokkos_ENABLE_CUDA`](https://kokkos.org/kokkos-core-wiki/keywords.html#backend-selection) defined

### --hip

 - the instrumented language is `HIP`

 - linking against [`Kokkos::kokkos`](https://kokkos.org/kokkos-core-wiki/building.html#kokkos-philosophy) with
   [`Kokkos_ENABLE_HIP`](https://kokkos.org/kokkos-core-wiki/keywords.html#backend-selection) defined

### --opencl

 - linking against [`OpenCL::OpenCL`](https://cmake.org/cmake/help/latest/module/FindOpenCL.html#imported-targets) with
   [`OpenCL_FOUND`](https://cmake.org/cmake/help/latest/module/FindOpenCL.html#result-variables) defined

### --openacc

 - linking against [`OpenACC::OpenACC_<lang>`](https://cmake.org/cmake/help/latest/module/FindOpenACC.html#imported-targets) with
   [`OpenACC_<lang>_FOUND`](https://cmake.org/cmake/help/latest/module/FindOpenACC.html#variables) defined

### --kokkos

 - linking against [`Kokkos::kokkos`](https://kokkos.org/kokkos-core-wiki/building.html#kokkos-philosophy) with
   [`Kokkos_FOUND`](https://kokkos.org/kokkos-core-wiki/building.html#kokkos-philosophy) defined


## Components

The following paragraphs list all automatically detected components for the find module and the arguments which trigger them.

Some arguments are regular expressions to signify that multiple arguments are matched.

### COMPILER_\<LANGUAGE\>_\<PATH\>

 - inferred from [`CMAKE_<LANG>_COMPILER`](https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_COMPILER.html) 

### MPI_COMPILER_\<LANGUAGE\>_\<PATH\>

 - inferred from [`MPI_<LANG>_COMPILER`](https://cmake.org/cmake/help/latest/module/FindMPI.html#variables-for-using-mpi)

### OPARI2

 - `--thread=omp:opari2`

### OMPT

 - `--thread=omp:ompt`

### OMP_\<lang\>

 - `--thread=omp(:.+)?`

 - `--openmp`

### PTHREAD

 - `--thread=pthread`

### MPP_mpi

 - `--mpp=mpi`

### MPP_shmem

 - `--mpp=shmem`

### IO_posix

 - `--io=posix`

### COMPILER

 - `--compiler`

### CUDA

 - `--cuda`

### PDT

 - `--pdt`

### OPENCL

 - `--opencl`

### OPENACC

 - `--openacc`

### MEMORY

 - `--memory`

### KOKKOS

 - `--kokkos`

### HIP

 - `--hip`
