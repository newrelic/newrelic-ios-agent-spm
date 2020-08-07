//
// Created by Bryce Buchanan on 6/13/17.
//

#ifndef LIBMOBILEAGENT_HEXCONTROLLER_HPP
#define LIBMOBILEAGENT_HEXCONTROLLER_HPP


#include "flatbuffers/flatbuffers.h"
#include "Hex/report/HexReport.hpp"
#include <Analytics/AnalyticsController.hpp>
#include "Hex/report/attributes/BooleanAttributes.hpp"
#include "Hex/report/attributes/LongAttributes.hpp"
#include "Hex/report/attributes/StringAttributes.hpp"
#include "Hex/report/attributes/DoubleAttributes.hpp"
#include "Hex/report/exception/Library.hpp"
#include "Hex/report/exception/Thread.hpp"
#include "Hex/HexPublisher.hpp"
#include "Hex/LibraryController.hpp"
#include "Hex/report/HexReport.hpp"
#include "HexStore.hpp"
#include "HexReportContext.hpp"

namespace NewRelic {
    namespace Hex {
        class HexController {
        public:
            HexController(std::shared_ptr<const AnalyticsController>& analytics,
                          std::shared_ptr<Report::AppInfo> appInfo,
                          HexPublisher* publisher,
                          std::shared_ptr<HexStore>& store,
                          const char* sessionId);

            HexController(std::shared_ptr<const AnalyticsController>&& analytics,
                          std::shared_ptr<Report::AppInfo> appInfo,
                          HexPublisher* publisher,
                          std::shared_ptr<HexStore>& store,
                          const char* sessionId);

            void submit(std::shared_ptr<Report::HexReport> report);

            void publish();

            void setSessionId(const char* sessionId);

            std::shared_ptr<Report::HexReport> createReport(uint64_t epochMs,
                                                            const char* message,
                                                            const char* name,
                                                            std::vector<std::shared_ptr<Report::Thread>> threads);


            virtual ~HexController() = default;

        protected:
            std::shared_ptr<HexReportContext> detachKeyContext();

        private:
            std::shared_ptr<const NewRelic::AnalyticsController> _analytics;
            std::shared_ptr<Report::AppInfo> _applicationInfo;
            HexPublisher* _publisher;
            std::shared_ptr<HexStore>& _store;
            std::string _sessionId;
            mutable std::mutex _keyContextMutex;
            std::shared_ptr<HexReportContext> _keyContext;
        };
    }
}


#endif //LIBMOBILEAGENT_HEXCONTROLLER_HPP
