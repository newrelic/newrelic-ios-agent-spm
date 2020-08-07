//
// Created by Bryce Buchanan on 9/25/17.
//

#ifndef LIBMOBILEAGENT_HEXPERSISTENCEMANAGER_HPP
#define LIBMOBILEAGENT_HEXPERSISTENCEMANAGER_HPP


#include "HexStore.hpp"
#include "HexPublisher.hpp"

namespace NewRelic {
    namespace Hex {
        class HexPersistenceManager {
        public:
            HexPersistenceManager(std::shared_ptr<HexStore>& store,
                                  HexPublisher* publisher);

            ~HexPersistenceManager() = default;

            std::shared_ptr<HexContext> retrieveStoreReports();

            void publishContext(std::shared_ptr<HexContext>const& context);

        private:
            std::shared_ptr<HexStore>& _store;
            HexPublisher* _publisher;
        };
    }
}


#endif //LIBMOBILEAGENT_HEXPERSISTENCEMANAGER_HPP
