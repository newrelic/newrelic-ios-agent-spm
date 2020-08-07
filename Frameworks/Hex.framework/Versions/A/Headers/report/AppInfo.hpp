//
// Created by Bryce Buchanan on 6/12/17.
//

#ifndef LIBMOBILEAGENT_APPINFO_HPP
#define LIBMOBILEAGENT_APPINFO_HPP


#include "Hex/generated/ios_generated.h"
#include "Hex/generated/hex_generated.h"
#include "Hex/generated/session-attributes_generated.h"
#include "Hex/generated/agent-data_generated.h"
#include "Hex/report/ApplicationLicense.hpp"

using namespace com::newrelic::mobile;
using namespace flatbuffers;

namespace NewRelic {
    namespace Hex {
        namespace Report {
            class AppInfo {
            public:
                AppInfo(ApplicationLicense* appLicense,
                        fbs::Platform platform);

                Offset<fbs::ApplicationInfo> serialize(flatbuffers::FlatBufferBuilder& builder) const;

            private:
                ApplicationLicense* _appLicense;
                fbs::Platform _platform;
            };
        }
    }
}


#endif //LIBMOBILEAGENT_APPINFO_HPP
