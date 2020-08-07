//
//

#ifndef LIBMOBILEAGENT_APPLICATION_HPP
#define LIBMOBILEAGENT_APPLICATION_HPP

#include <string>
#include "Utilities/ApplicationContext.hpp"

namespace NewRelic {
    class Application {
    private:
        ApplicationContext _context;
        static Application* __instance;
        explicit Application();
    public:
        bool isValid();
        static Application& getInstance();
        const ApplicationContext& getContext() const;
        void setContext(ApplicationContext&& context);
    };
} // namespace NewRelic
#endif //LIBMOBILEAGENT_APPLICATION_HPP
