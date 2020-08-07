#ifndef JSON_HH
#define JSON_HH

#include "json_st.hh" // JSON syntax tree
#include "json.tab.hh" // parser
  
NRJSON::JsonValue parse_file(const char* filename);
NRJSON::JsonValue parse_string(const std::string& s);

#endif
