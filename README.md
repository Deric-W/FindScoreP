# FindScoreP

CMake find module for [Score-P](https://score-p.org).

## Usage

Place the module somewhere in your [`CMAKE_MODULE_PATH`](https://cmake.org/cmake/help/latest/variable/CMAKE_MODULE_PATH.html) and use

```cmake
find_package(ScoreP)
```

The find module can handle multiple installed versions and version ranges.

### Imported Targets

`ScoreP::ScoreP`, the scorep executable.

`ScoreP::Config`, the scorep-config executable.

### Result Variables

`SCOREP_FOUND`, True if a matching Score-P installation was found.

`SCOREP_EXECUTABLE`, the path of the scorep executable.

`SCOREP_CONFIG_EXECUTABLE`, the path of the scorep-config executable.

`SCOREP_VERSION_STRING`, the version of Score-P found.

## Tests

Testing using the [CTest](https://cmake.org/cmake/help/latest/module/CTest.html)
module requires Score-P and a POSIX compatible shell to be installed.