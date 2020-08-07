#include <string>

#include "Utilities/BaseValue.hpp"

#ifndef __String_H_
#define __String_H_

namespace NewRelic {
    class Value;
    class String : public BaseValue {
    friend class Value;
    private:
        std::string _value;
        String(const char* value);
        String(std::istream& is);
        std::string replaceAll(std::string str, const std::string& from, const std::string& to) const;

    public:
        String(const String& copy);
        virtual ~String();
        virtual void put(std::ostream& os) const;
        friend std::ostream& operator<<(std::ostream& os, const String& dt);
        virtual bool equal(const BaseValue& value) const;
        friend bool operator==(const String& rhs, const String& lhs);
        const std::string getValue();
    };
}
#endif

