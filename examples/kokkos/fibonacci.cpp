#include <iostream>
#include <sys/types.h>
#include <vector>
#include <boost/program_options.hpp>
#include <Kokkos_Core.hpp>

namespace options = boost::program_options;

static unsigned long fibonacci(unsigned long element) {
    unsigned long a = 0;
    unsigned long b = 1;
    while (element > 0) {
        auto tmp = a + b;
        a = b;
        b = tmp;
        element--;
    }
    return a;
}

static void calculate_elements(const unsigned int start, const unsigned int step, Kokkos::View<unsigned long*> buffer) {
    Kokkos::parallel_for("fibonacci", buffer.extent(0), KOKKOS_LAMBDA (unsigned int index) {
        buffer(index) = fibonacci(start + index * step);
    });
}

static void print_elements(const unsigned int start, const unsigned int step, Kokkos::View<unsigned long*>::HostMirror buffer) {
    std::cout << "Calculated elements:\n";
    auto element = start;
    for (auto index = 0u; index < buffer.extent(0); index++) {
        std::cout << element << ": " << buffer(index) << "\n";
        element += step;
    }
}

int main(int argc, char** argv) {
    unsigned int start, step, count;

    options::options_description desc("Allowed options");
    desc.add_options()
        ("help,h", "display help message")
        ("start", options::wvalue<unsigned int>(&start)->required(), "starting index of the fibonacci sequence")
        ("step", options::value<unsigned int>(&step)->required(), "step size between the calculated values")
        ("count", options::value<unsigned int>(&count)->required(), "amount of elements to be calculated");
    options::positional_options_description positionals;
    positionals
        .add("start", 1)
        .add("step", 1)
        .add("count", 1);

    options::variables_map arguments;

    try {
        auto parsed = options::command_line_parser(argc, argv).options(desc).positional(positionals).style(options::command_line_style::unix_style).run();
        options::store(parsed, arguments);
        if (arguments.count("help")) {
            std::cout << "OpenMP example which calculates elements of the fibonacci sequence" << "\n\n";
            std::cout << "Usage: fibonacci [OPTIONS] [start step count]" << "\n";
            std::cout << desc << "\n";
            return 0;
        }
        options::notify(arguments);
    } catch (options::error& e) {
        std::cerr << "Error while parsing arguments: " << e.what() << "\n";
        return 1;
    }

    Kokkos::ScopeGuard kokkos(argc, argv);
    Kokkos::View<unsigned long*> buffer("buffer", count);
    printf("Calculating elements with start: %u, step: %u and count: %u\n", start, step, count);
    calculate_elements(start, step, buffer);
    auto hostMirror = Kokkos::create_mirror_view(buffer);
    Kokkos::deep_copy(hostMirror, buffer);
    print_elements(start, step, hostMirror);
    return 0;
}