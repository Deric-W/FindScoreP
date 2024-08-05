#include <iostream>
#include <vector>
#include <thread>
#include <algorithm>
#include <boost/program_options.hpp>
#include <pthread.h>

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

static void fibonacci_multiple(std::vector<unsigned long>::iterator begin, std::vector<unsigned long>::iterator end, unsigned int start, unsigned int step) {
    for (auto it = begin; it != end; it++) {
        *it = fibonacci(start);
        start += step;
    }
}

struct thread_argument {
    std::vector<unsigned long>::iterator begin;

    std::vector<unsigned long>::iterator end;

    unsigned int start;

    unsigned int step;
};

static void * thread_function(void *arg) {
    auto argument = static_cast<thread_argument*>(arg);
    fibonacci_multiple(argument->begin, argument->end, argument->start, argument->step);
    return nullptr;
}

static void calculate_elements(const unsigned int start, const unsigned int step, std::vector<unsigned long>* buffer) {
    if (buffer->empty()) {
        return;
    }
    const unsigned int cpus = std::min(std::thread::hardware_concurrency(), (unsigned int)buffer->size());
    thread_argument arguments[cpus];
    pthread_t threads[cpus];
    const unsigned int elementsPerThread = buffer->size() / cpus;
    for (unsigned int cpu = 0; cpu < cpus; cpu++) {
        auto begin = buffer->begin() + elementsPerThread * cpu;
        arguments[cpu] = {
            begin,
            begin + elementsPerThread,
            start + step * elementsPerThread * cpu,
            step
        };
        pthread_create(&threads[cpu], nullptr, &thread_function, &arguments[cpu]);
    }

    fibonacci_multiple(
        buffer->begin() + elementsPerThread * cpus,
        buffer->end(),
        start + step * elementsPerThread * cpus,
        step
    );

    for (unsigned int cpu = 0; cpu < cpus; cpu++) {
        pthread_join(threads[cpu], nullptr);
    }
}

static void print_elements(const unsigned int start, const unsigned int step, std::vector<unsigned long>* buffer) {
    std::cout << "Calculated elements:\n";
    auto element = start;
    for (auto value: *buffer) {
        std::cout << element << ": " << value << "\n";
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
            std::cout << "pthread example which calculates elements of the fibonacci sequence" << "\n\n";
            std::cout << "Usage: fibonacci [OPTIONS] [start step count]" << "\n";
            std::cout << desc << "\n";
            return 0;
        }
        options::notify(arguments);
    } catch (options::error& e) {
        std::cerr << "Error while parsing arguments: " << e.what() << "\n";
        return 1;
    }

    std::vector<unsigned long> buffer(count);
    printf("Calculating elements with start: %u, step: %u and count: %u\n", start, step, count);
    calculate_elements(start, step, &buffer);
    print_elements(start, step, &buffer);
    return 0;
}