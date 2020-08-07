//
// Created by Bryce Buchanan on 7/11/17.
//

#ifndef LIBMOBILEAGENT_HEXAUDITOR_HPP
#define LIBMOBILEAGENT_HEXAUDITOR_HPP

#include <cstdint>
#include <string>
#include <Hex/generated/ios_generated.h>
#include <Hex/generated/hex_generated.h>
#include <Hex/generated/session-attributes_generated.h>
#include <Hex/generated/agent-data_generated.h>
#include <Hex/generated/agent-data-bundle_generated.h>
#include <sstream>

using namespace com::newrelic::mobile;
namespace NewRelic {
    namespace Hex {
        class HexAuditor {
        public:
            void audit(uint8_t* buf);

        private:
            std::stringstream ss;

            void printStringWithIndentation(const char* string,
                                            int indentation);

            void
            printStringAttributes(const flatbuffers::Vector<flatbuffers::Offset<fbs::StringSessionAttribute>>* attributes,
                                  int indent);

            void
            printLongAttributes(const flatbuffers::Vector<flatbuffers::Offset<fbs::LongSessionAttribute>>* attributes,
                                int indent);

            void
            printDoubleAttributes(const flatbuffers::Vector<flatbuffers::Offset<fbs::DoubleSessionAttribute>>* attributes,
                                  int indent);

            void
            printBoolAttributes(const flatbuffers::Vector<flatbuffers::Offset<fbs::BoolSessionAttribute>>* attributes,
                                int indent);

            void printApplicationinfo(const fbs::ApplicationInfo* info,
                                      int indent);

            void
            printHandledExceptions(const flatbuffers::Vector<flatbuffers::Offset<com::newrelic::mobile::fbs::hex::HandledException> >* exceptions,
                                   int indent);

            void printHandledException(const fbs::hex::HandledException* hex,
                                       int indent);

            void printApplicationLicense(const fbs::ApplicationLicense* license,
                                         int indent);

            void printThreads(const flatbuffers::Vector<flatbuffers::Offset<fbs::hex::Thread>>* threads,
                              int indent);

            void printThread(const flatbuffers::Vector<flatbuffers::Offset<fbs::hex::Frame>>* frames,
                             int indent);

            void printLibraries(const flatbuffers::Vector<flatbuffers::Offset<fbs::ios::Library>>* libraries,
                                int indent);
        };
    }
}


#endif //LIBMOBILEAGENT_HEXAUDITOR_HPP
