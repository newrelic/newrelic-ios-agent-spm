#include <functional>

#ifndef __AttributeValidator_H_
#define __AttributeValidator_H_


namespace NewRelic{
class AttributeValidator {
    private:
    std::function<bool(const char*)> _nameValidator;
    std::function<bool(const char*)> _valueValidator;
    std::function<bool(const char*)> _eventTypeValidator;

public:
    AttributeValidator(std::function<bool(const char*)> nameValidator,
                       std::function<bool(const char*)> valueValidator,
                       std::function<bool(const char*)> eventTypeValidator);

    const std::function<bool(const char*)>& getNameValidator() const;
    const std::function<bool(const char*)>& getValueValidator() const;
    const std::function<bool(const char*)>& getEventTypeValidator() const;

};
}


#endif //__AttributeValidator_H_
