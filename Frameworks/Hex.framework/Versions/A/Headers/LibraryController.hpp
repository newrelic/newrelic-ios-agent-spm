//
// Created by Jared Stanbrough on 6/26/17.
//

#ifndef LIBMOBILEAGENT_LIBRARYCONTROLLER_HPP
#define LIBMOBILEAGENT_LIBRARYCONTROLLER_HPP

#include <vector>
#include <mutex>
#include "Hex/report/exception/Library.hpp"
#include "Hex/generated/ios_generated.h"

using namespace com::newrelic::mobile;
using std::vector;

namespace NewRelic {
    class LibraryController {
    public:
        static LibraryController& getInstance() {
            static LibraryController instance;
            if (!instance.is_initialized()) {
                instance.initialize();
            }
            return instance;
        }

        void add_library(const char* name,
                         const uint8_t* uuid,
                         uint64_t address,
                         com::newrelic::mobile::fbs::ios::Arch arch,
                         uint64_t size
        );

        std::vector<Hex::Report::Library> libraries() {
            return library_images;
        }

        size_t num_images() {
            std::lock_guard<std::mutex> libraryLock(libraryContainerMutex);

            return library_images.size();
        }

        const Hex::Report::Library getAppImage() {
            std::lock_guard<std::mutex> libraryLock(libraryContainerMutex);

            return library_images[0];
        }

        std::mutex& getLibraryMutex() {
            return libraryContainerMutex;
        }

        LibraryController(LibraryController const& copy) = delete;

        void operator=(LibraryController const&) = delete;

    private:
        std::vector<std::string> USER_LIBRARY_PATHS;
        std::vector<Hex::Report::Library> library_images;
        mutable std::mutex libraryContainerMutex;
        bool initialized = false;

        LibraryController() : library_images() {
            USER_LIBRARY_PATHS = {"/private", "/var/containers/Bundle/Application",
                                  "/var/mobile/Containers/Bundle/Application", "/var/mobile/Applications/"};
        };

        void register_handler();

        bool is_initialized() { return initialized; }

        void initialize() {
            initialized = true;
            register_handler();
        }
    };
}


#endif //LIBMOBILEAGENT_LIBRARYCONTROLLER_HPP
