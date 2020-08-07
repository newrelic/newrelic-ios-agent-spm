//
// Created by Bryce Buchanan on 6/12/17.
//

#ifndef LIBMOBILEAGENT_CONTEXT_HPP
#define LIBMOBILEAGENT_CONTEXT_HPP

#include "Hex/report/attributes/BooleanAttributes.hpp"
#include "Hex/report/attributes/StringAttributes.hpp"
#include "Hex/report/attributes/LongAttributes.hpp"
#include "Hex/report/attributes/DoubleAttributes.hpp"
#include "Hex/report/exception/HandledException.hpp"
#include "Hex/report/AgentData.hpp"
#include <Analytics/AttributeValidator.hpp>
#include "Hex/report/HexReport.hpp"

#include <JSON/json_st.hh>
#include <Analytics/AttributeBase.hpp>

namespace NewRelic {
    namespace Hex {
        class HexContext {
        public:
            HexContext();

            virtual void finalize();

            std::shared_ptr<flatbuffers::FlatBufferBuilder> getBuilder();

        private:
            std::shared_ptr<flatbuffers::FlatBufferBuilder> builder;
        };
    }
}

#endif //LIBMOBILEAGENT_CONTEXT_HPP
