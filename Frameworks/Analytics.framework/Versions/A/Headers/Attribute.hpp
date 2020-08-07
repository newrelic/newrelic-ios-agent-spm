
#include <Utilities/Value.hpp>
#include "AttributeBase.hpp"
#include <string>
#include <functional>
#ifndef __Attribute_H_
#define __Attribute_H_



namespace NewRelic {
    template<typename T>
    class Attribute {
        const std::string _name;
        std::shared_ptr<BaseValue> _value;
        static std::shared_ptr<BaseValue> createValue(T value) {
            return Value::createValue(value);
        }
    public:
        //throws std::out_of_range, std::length_error
        static std::shared_ptr<AttributeBase> createAttribute(const char *name,
                                                              std::function<bool(const char*)> nameValidator,
                                                              T value,
                                                              std::function<bool(T)> valueValidator) { //throws invalid_argument

            bool isNameValid = nameValidator(name);
            bool isValueValid = valueValidator(value);

            if (isNameValid && isValueValid) {
                std::shared_ptr<BaseValue> ptr = Attribute::createValue(value);
                //throws std::out_of_range, std::length_error
                return std::shared_ptr<AttributeBase>(new AttributeBase(std::string(name),ptr));
            }

            return nullptr;
        }
    };



}
#endif //__Attribute_H_
