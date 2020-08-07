
#include "Utilities/Number.hpp"
#include "Utilities/String.hpp"
#include "Utilities/Boolean.hpp"

#ifndef __Value_H_
#define __Value_H_
namespace NewRelic {
    class Value {
    private:
        Value();

    public:
        static std::shared_ptr<Boolean> createValue(bool);
        static std::shared_ptr<String> createValue(const char*);
        static std::shared_ptr<Number> createValue(double);
        static std::shared_ptr<Number> createValue(long long);
        static std::shared_ptr<Number> createValue(unsigned long long);
        static std::shared_ptr<Number> createValue(int);
        static std::shared_ptr<Number> createValue(unsigned int);
        static std::shared_ptr<BaseValue> createValue(std::istream& is);
    };

}
#endif
