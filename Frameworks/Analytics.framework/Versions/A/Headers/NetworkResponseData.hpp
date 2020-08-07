#ifndef LIBMOBILEAGENT_NETWORKRESPONSEDATA_HPP
#define LIBMOBILEAGENT_NETWORKRESPONSEDATA_HPP

namespace NewRelic {
    class NetworkResponseData {
    public:
        // Successful Network Response
        NetworkResponseData(unsigned int statusCode,
                            unsigned int bytesReceived,
                            double responseTime);

        // Network Error Response
        NetworkResponseData(int networkErrorCode,
                            unsigned int bytesReceived,
                            double responseTime,
                            const char *networkErrorMessage);

        // HTTP Error Response
        NetworkResponseData(unsigned int statusCode,
                            unsigned int bytesReceived,
                            double responseTime,
                            const char *networkErrorMessage,
                            const char *encodedResponseBody,
                            const char *appDataHeader);

        const char *getEncodedResponseBody() const;
        const char *getAppDataHeader() const;
        double getResponseTime() const;
        unsigned int getBytesReceived() const;
        unsigned int getStatusCode() const;
        const char *getNetworkErrorMessage() const;
        int getNetworkErrorCode() const;

    private:
        const char *_encodedResponseBody;
        const char *_appDataHeader;
        double _responseTime;
        unsigned int _bytesReceived;
        unsigned int _statusCode;
        const char *_networkErrorMessage;
        int _networkErrorCode;
    };

}
#endif //LIBMOBILEAGENT_NETWORKRESPONSEDATA_HPP
