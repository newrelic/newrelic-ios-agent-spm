//
// Created by Bryce Buchanan on 9/21/17.
//

#ifndef LIBMOBILEAGENT_HEXSTORE_HPP
#define LIBMOBILEAGENT_HEXSTORE_HPP


#include <memory>
#include <string>
#include <future>
#include "report/HexReport.hpp"

namespace NewRelic {
    namespace Hex {
        class HexStore {
        public:

            explicit HexStore(const char* storePath);

            void store(const std::shared_ptr<Report::HexReport>& report);

            /*
             * readAll()
             * executes callback closure on new thread with flatbuffer data array as parameter.
             *
             * The uint8_t buffer param will be freed after the closure is complete.
             */
            std::future<bool> readAll(std::function<void(uint8_t*, std::size_t)> callback);

            void clear();

        protected:
            virtual std::string generateFilename();

            std::string storePath = ".";
            std::string filename = "";
        private:
            static const char* FILE_BASE;
            static const char* FILE_EXTENSION;
            mutable std::mutex _storeMutex;
        };
    }
}


#endif //LIBMOBILEAGENT_HEXSTORE_HPP
