//
// Created by Bryce Buchanan on 11/2/15.
//

#ifndef LIBMOBILEAGENT_BOOLEAN_HPP
#define LIBMOBILEAGENT_BOOLEAN_HPP

#include <mach/std_types.h>
#include "Utilities/BaseValue.hpp"

namespace NewRelic{
    class Value;
    class Boolean : public BaseValue {
        friend class Value;
    private:
        bool _value;

        Boolean(std::istream& is);
    public:
        Boolean(const Boolean& copy);
        Boolean(bool value);
        virtual ~Boolean();
        virtual bool equal(const BaseValue& value) const;
        virtual void put(std::ostream& os) const;
        friend std::ostream& operator<<(std::ostream& os, const Boolean& boolean);
        const bool getValue() const;
    };
}

#endif //LIBMOBILEAGENT_BOOLEAN_HPP
