include(ScorePUtilities)

_scorep_arguments2settings("--thread=pthread" 10 TEST1)
_scorep_arguments2settings("--thread=omp" 10 TEST2)
_scorep_merge_settings(TEST1 TEST2 MERGED)
_scorep_settings2arguments(MERGED merged)
