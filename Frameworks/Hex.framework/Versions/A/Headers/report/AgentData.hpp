//
// Created by Bryce Buchanan on 6/12/17.
//

#ifndef LIBMOBILEAGENT_AGENTDATA_HPP
#define LIBMOBILEAGENT_AGENTDATA_HPP


#include "Hex/report/attributes/StringAttributes.hpp"
#include "Hex/report/attributes/BooleanAttributes.hpp"
#include "Hex/report/attributes/DoubleAttributes.hpp"
#include "Hex/report/attributes/LongAttributes.hpp"
#include "Hex/generated/ios_generated.h"
#include "Hex/generated/hex_generated.h"
#include "Hex/generated/agent-data_generated.h"
#include "Hex/report/AppInfo.hpp"
#include "Hex/report/exception/HandledException.hpp"


namespace NewRelic {
    namespace Hex {
        namespace Report {
            class AgentData {
            public:
                AgentData(const std::shared_ptr<StringAttributes>& stringAttributes,
                          const std::shared_ptr<BooleanAttributes>& booleanAttributes,
                          const std::shared_ptr<DoubleAttributes>& doubleAttributes,
                          const std::shared_ptr<LongAttributes>& longAttributes,
                          const std::shared_ptr<AppInfo>& applicationInfo,
                          std::shared_ptr<HandledException> handledException);

                Offset<fbs::AgentData> serialize(flatbuffers::FlatBufferBuilder& builder) const;

            private:
                const std::shared_ptr<StringAttributes>& _stringAttributes;
                const std::shared_ptr<BooleanAttributes>& _booleanAttributes;
                const std::shared_ptr<DoubleAttributes>& _doubleAttributes;
                const std::shared_ptr<LongAttributes>& _longAttributes;
                const std::shared_ptr<AppInfo>& _applicationInfo;
                std::shared_ptr<HandledException> _handledException;

            };
        }
    }
}
#endif //LIBMOBILEAGENT_AGENTDATA_HPP
