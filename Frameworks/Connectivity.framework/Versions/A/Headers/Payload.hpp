#ifndef LIBMOBILEAGENT_CATPAYLOAD_HPP
#define LIBMOBILEAGENT_CATPAYLOAD_HPP

#include <vector>

#include <JSON/IJsonable.hpp>

#include "PayloadType.hpp"

namespace NewRelic {
namespace Connectivity {


/*
 * Payload is based off of the distributed tracing spec defined here
 * https://source.datanerd.us/earnold/agent-specs/blob/new-connectivity/Distributed-Tracing.md
 */
class Payload : public NRJSON::IJsonable {
public:
    Payload() = default;

    virtual NRJSON::JsonObject toJSON();

    //accessors
    const std::vector<int> &getVersion() const;

    void setVersion(const std::vector<int> &version);

    const PayloadType &getType() const;

    void setType(const PayloadType &type);

    const std::string &getAccountId() const;

    void setAccountId(const std::string &accountId);

    const std::string &getAppId() const;

    void setAppId(const std::string &appId);

    const std::string &getId() const;

    void setId(const std::string &id);

    const std::string &getTraceId() const;

    void setTraceId(const std::string& traceId);

    const std::string &getParentId() const;

    void setParentId(const std::string &parentId);

    long long int getTimestamp() const;

    void setTimestamp(long long int timestamp);

private:

    //current spec has version 0,2 this won't change from build to build
    std::vector<int> version = {0,2};

    //the type will likely always be mobile.
    PayloadType type = PayloadType(PayloadType::mobile);

    //the account id
    std::string accountId;

    //the application id
    std::string appId;

    //a randomly generated value unique to the instance of Payload
    std::string id;

    //a randomly generated value unique to the trace (many payloads may have the same traceId)
    std::string traceId;

    //the parent payload id
    std::string parentId;

    //unix epoch timestamp in milliseconds
    long long timestamp;
};

} //namespace Connectivity
} //namespace NewRelic
#endif //LIBMOBILEAGENT_CATPAYLOAD_HPP
