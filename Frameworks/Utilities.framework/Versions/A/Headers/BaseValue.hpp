#ifndef __BaseValue_H_
#define __BaseValue_H_

#include <memory>
#include <ostream>
namespace NewRelic {
    class BaseValue {
    public:
        static const char _delimiter = '\t';
        BaseValue(const BaseValue& copy);
        virtual ~BaseValue();


        friend std::ostream& operator<<(std::ostream& os, const BaseValue& dt);
        friend bool operator==(const BaseValue& lhs, const BaseValue& rhs);
        virtual void put(std::ostream& os) const = 0;
        virtual bool equal(const BaseValue& value)const=0;
        enum class Category {NUMBER=1,STRING,BOOLEAN};
        friend std::ostream& operator<< (std::ostream& os, const BaseValue::Category& dt);
        friend std::istream& operator>> (std::istream& os, BaseValue::Category& dt);
        Category getCategory() const;
    protected:
        BaseValue(Category category);
    private:
        Category _category;
    };


}


// TODO: Research shared_ptr and inheritance with equivalence operator overloading
//
//template<> std::shared_ptr<NewRelic::BaseValue>::operator==(const std::shared_ptr<NewRelic::BaseValue>& lhs, const std::shared_ptr<NewRelic::BaseValue>& rhs) {
//    return *lhs == *rhs;
//}
#endif
