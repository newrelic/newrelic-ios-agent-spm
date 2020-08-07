//
// Created by Bryce Buchanan on 8/10/15.
//


#ifndef PROJECT_UTIL_HPP
#define PROJECT_UTIL_HPP

#include <string>
#include <map>

namespace NewRelic {
    class Util {
    public:
        class Strings {
        private:
            static const std::map<std::string,std::string> _replacement_values;
        public:
            //throws std::out_of_range, std::length_error
            static std::string& escapeCharacterLiterals(std::string& string);  //l-values
            //throws std::out_of_range, std::length_error
            static std::string& escapeCharacterLiterals(std::string&& string); //r-values
            //throws std::out_of_range, std::length_error
            static std::string& replaceCharactersInString(std::string& string,const std::map<std::string,std::string>& replacementMap);
        };
    };
}
#endif //PROJECT_UTIL_HPP
