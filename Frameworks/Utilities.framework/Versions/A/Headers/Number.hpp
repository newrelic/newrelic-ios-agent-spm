#include <mach/std_types.h>
#include "Utilities/BaseValue.hpp"
#ifndef __Number_H_
#define __Number_H_
namespace NewRelic {
    class Value;
    class Number : public BaseValue {
    friend class Value;
    public:
        enum class Tag  {DOUBLE=1,LONG, U_LONG};
        friend std::ostream& operator<<(std::ostream& os, const Number::Tag& tag);
        friend std::istream& operator>>(std::istream& is, const Number::Tag& tag);
        Number(const Number& copy);
        Number(std::istream& is);
        virtual ~Number();

        virtual bool equal(const BaseValue& value)const;
        virtual void put(std::ostream& os) const;
        friend std::ostream& operator<<(std::ostream& os, const Number& dt);
        friend std::istream& operator>>(std::istream& os, Number& dt);

        double doubleValue() const;
        __int64_t longLongValue() const;
        __uint64_t unsignedLongLongValue() const;

        Tag getTag() const;

    private:
        Number(int _value);
        Number(double _value);
        Number(__int64_t _value);
        Number(__uint64_t _value);
        union {
            double dbl;
            __int64_t ll;
            __uint64_t ull;
        };
        Tag tag;
    };


}
#endif
