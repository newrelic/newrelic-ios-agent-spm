//
//

#ifndef LIBMOBILEAGENT_APPLICATIONCONTEXT_HPP
#define LIBMOBILEAGENT_APPLICATIONCONTEXT_HPP

#include <string>

namespace NewRelic {
class ApplicationContext {
private:
    std::string accountId;
    std::string applicationId;
public:
    ApplicationContext(const std::string& accountId, const std::string& applicationId);
    ApplicationContext(const std::string&& accountId, const std::string&& applicationId);

    const std::string& getApplicationId() const;

    const std::string& getAccountId() const;
};
} // namespace NewRelic
#endif //LIBMOBILEAGENT_APPLICATIONCONTEXT_HPP
