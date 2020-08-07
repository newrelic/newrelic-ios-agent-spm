#include <string>
#include <Utilities/BaseValue.hpp>

#ifndef __AttributeBase_H_
#define __AttributeBase_H_

namespace NewRelic  {
    class AttributeBase {
    private:
        const std::string _name;
        std::shared_ptr<BaseValue> _value;
        bool _isPersistent{false};
    public:
        AttributeBase(std::string key, std::shared_ptr<BaseValue> value); //will std::move string
        friend bool operator==(const AttributeBase& lhs, const AttributeBase& rhs);
        std::string getName() const;
        std::shared_ptr<BaseValue> getValue() const;
        void setValue(std::shared_ptr<BaseValue> value);
        void setPersistent(bool persistence);
        bool getPersistent() const;
    };

}
#endif //__AttributeBase_H_
