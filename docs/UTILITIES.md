# ScorePUtilities Module

## Functions

After including the `ScorePUtilities` module the following functions are available:

`scorep_instrument(target)`, which configures a target to be instrumented by Score-P and supports the following keywords:

 - `OVERRIDE`, an option that when enabled allows overwriting existing `<LANG>_COMPILER_LAUNCHER` and `<LANG>_LINKER_LAUNCHER` properties

 - `LANGS`, a multi-value keyword which lists the names of the languages to instrument

 - `ARGUMENTS`, a multi-value keyword which lists the commandline arguments to Score-P

 - `AUTO`, an option which enables [automatic detection](AUTODETECT.md#Arguments) of Score-P arguments

This function ignores the `SCOREP_LANGUAGES` and `SCOREP_ARGUMENTS` properties and is intended to be used through `scorep_enable`.

`scorep_mark_instrumented()`, which marks targets to be instrumented when calling `scorep_enable` and supports the following keywords:

 - `DIRECTORIES`, a multi-value keyword which lists directories in which all targets should be instrumented

 - `TARGETS`, a multi-value keyword which lists targets which should be instrumented

 - `LANGS`, a multi-value keyword which lists the names of the languages to instrument

 - `ARGUMENTS`, a multi-value keyword which lists the commandline arguments to Score-P

 - `AUTO`, an option which enables [automatic detection](AUTODETECT.md#Arguments) of Score-P arguments

The function defaults to the current directory if no directories or targets are passed
and does by itself nothing besides setting the `SCOREP_LANGUAGES` and `SCOREP_<LANG>_ARGUMENTS` properties.

`scorep_required_components(outVar)`, which stores the components required for the instrumentation of targets marked by `scorep_mark_instrumented` in outVar and supports the following keywords:

 - `DIRECTORIES`, a multi-value keyword which lists directories in which all targets should be checked

 - `TARGETS`, a multi-value keyword which lists targets which should be checked

 - `AUTO`, an option which additionally enables [automatic detection](AUTODETECT.md#Components) of the following components:

   - `COMPILER_<LANGUAGE>_<PATH>`

   - `MPI_COMPILER_<LANGUAGE>_<PATH>`

The function defaults to the current directory if no directories or targets are passed.

`scorep_enable()`, which instruments targets marked by `scorep_mark_instrumented` and supports the following keywords:

 - `DIRECTORIES`, a multi-value keyword which lists directories in which all targets should be checked

 - `TARGETS`, a multi-value keyword which lists targets which should be checked

 - `OVERRIDE`, an option that when enabled allows overwriting existing `<LANG>_COMPILER_LAUNCHER` and `<LANG>_LINKER_LAUNCHER` properties

The function defaults to the current directory if no directories or targets are passed.

## Properties

The `ScorePUtilities` module uses or defines the following properties:

 - `SCOREP_LANGUAGES`, a target property which when contains all languages to be instrumented when calling `scorep_enable`.

 - `SCOREP_<LANG>_ARGUMENTS`, a target property which contains command line arguments to Score-P for instrumenting language LANG.

 - `SCOREP_LANGUAGES_<TARGET>`, a cache variable which may override the `SCOREP_LANGUAGES` property of a target.

 - `SCOREP_<LANG>_ARGUMENTS_<TARGET>`, a cache variable which may override the `SCOREP_<LANG>_ARGUMENTS` property of a target.

The cache variables are intended to be set by users who wish to override which and how targets are instrumented when calling `scorep_enable`.
