#ifndef JSON_ST_HH
#define JSON_ST_HH

#include <iostream>
#include <map>
#include <vector>
#include <stack>

namespace NRJSON
{

    /** Possible JSON type of a value (array, object, bool, ...). */
    enum ValueType
    {
        INT,        // JSON's int
        FLOAT,      // JSON's float 3.14 12e-10
        BOOL,       // JSON's boolean (true, false)
        STRING,     // JSON's string " ... " or (not really JSON) ' ... '
        OBJECT,     // JSON's object { ... }
        ARRAY,      // JSON's array [ ... ]
        NIL         // JSON's null
    };

    // Forward declaration
    class JsonValue;

    /** A JSON object, i.e., a container whose keys are strings, this
    is roughly equivalent to a Python dictionary, a PHP's associative
    array, a Perl or a C++ map (depending on the implementation). */
    class JsonObject
    {

    public:
        static std::string escapeJsonControlCharacters(std::string string);

        /** Constructor. */
        JsonObject();
    
        /** Copy constructor. 
            @param o object to copy from
        */
        JsonObject(const JsonObject & o);
    
        /** Move constructor. */
        JsonObject(JsonObject && o);
    
        /** Assignment operator. 
            @param o object to copy from
        */
        JsonObject & operator=(const JsonObject & o);
    
        /** Move operator. 
            @param o object to copy from
        */
        JsonObject & operator=(JsonObject && o);
    
        /** Destructor. */
        ~JsonObject();

        /** Subscript operator, access an element by key.
            @param key key of the object to access
        */
        JsonValue & operator[] (const std::string& key);

        /** Subscript operator, access an element by key.
            @param key key of the object to access
        */
        const JsonValue & operator[] (const std::string& key) const;

        /** Retrieves the starting iterator (const).
            @remark mainly for printing
        */
        std::map<std::string, JsonValue>::const_iterator begin() const;

        /** Retrieves the ending iterator (const).
            @remark mainly for printing
        */
        std::map<std::string, JsonValue>::const_iterator end() const;
    
        /** Retrieves the starting iterator */
        std::map<std::string, JsonValue>::iterator begin();

        /** Retrieves the ending iterator */
        std::map<std::string, JsonValue>::iterator end();
    
        /** Inserts a field in the object.
            @param v pair <key, value> to insert
            @return an iterator to the inserted object
        */
        std::pair<std::map<std::string, JsonValue>::iterator, bool> insert(const std::pair<std::string, JsonValue>& v);

        /** Size of the object. */
        size_t size() const;

    protected:

        /** Inner container. */
        std::map<std::string, JsonValue> _object;
    };

    /** A JSON array, i.e., an indexed container of elements. It contains
    JSON values, that can have any of the types in ValueType. */
    class JsonArray
    {
    public:

        /** Default Constructor. */
        JsonArray();
    
        /** Destructor. */
        ~JsonArray();
    
        /** Copy constructor. 
            @param a the array to copy from
        */
        JsonArray(const JsonArray & a);
    
        /** Assignment operator. 
            @param a array to copy from
        */
        JsonArray & operator=(const JsonArray & a);
    
        /** Move constructor. 
            @param a the array to move from
        */
        JsonArray(JsonArray && a);

        /** Move assignment operator. 
            @param a array to move from
        */
        JsonArray & operator=(JsonArray && a);

        /** Subscript operator, access an element by index. 
            @param i index of the element to access
        */
        JsonValue & operator[] (size_t i);
        
        /** Subscript operator, access an element by index. 
            @param i index of the element to access
        */
        const JsonValue & operator[] (size_t i) const;

        /** Retrieves the starting iterator (const).
            @remark mainly for printing
        */
        std::vector<JsonValue>::const_iterator begin() const;

        /** Retrieves the ending iterator (const).
            @remark mainly for printing
        */
        std::vector<JsonValue>::const_iterator end() const;

        /** Retrieves the starting iterator. */
        std::vector<JsonValue>::iterator begin();

        /** Retrieves the ending iterator */
        std::vector<JsonValue>::iterator end();

        /** Inserts an element in the array.
            @param n (a pointer to) the value to add
        */
        void push_back(const JsonValue & n);
    
        /** Size of the array. */
        size_t size() const;

    protected:

        /** Inner container. */
        std::vector<JsonValue> _array;

    };

    /** A JSON value. Can have either type in ValueTypes. */
    class JsonValue
    {
    public:

        /** Default constructor (type = NIL). */
        JsonValue();
    
        /** Copy constructor. */
        JsonValue(const JsonValue & v);
    
        /** Constructor from int. */
        JsonValue(const long long int i);
    
        /** Constructor from int. */
        JsonValue(const long int i);
    
        /** Constructor from int. */
        JsonValue(const int i);
    
        /** Constructor from float. */
        JsonValue(const long double f);
        
        /** Constructor from float. */
        JsonValue(const double f);
    
        /** Constructor from bool. */
        JsonValue(const bool b);
    
        /** Constructor from pointer to char (C-string).  */
        JsonValue(const char* s);

        /** Constructor from STD string  */
        JsonValue(const std::string& s);
    
        /** Constructor from pointer to Object. */
        JsonValue(const JsonObject & o);
    
        /** Constructor from pointer to Array. */
        JsonValue(const JsonArray & a);
    
        /** Move constructor. */
        JsonValue(JsonValue && v);
    
        /** Move constructor from STD string  */
        JsonValue(std::string&& s);
    
        /** Move constructor from pointer to Object. */
        JsonValue(JsonObject && o);
    
        /** Move constructor from pointer to Array. */
        JsonValue(JsonArray && a);
    
        /** Type query. */
        ValueType type() const
        {
            return type_t;
        }
    
        /** Subscript operator, access an element by key.
            @param key key of the object to access
        */
        JsonValue & operator[] (const std::string& key);

        /** Subscript operator, access an element by key.
            @param key key of the object to access
        */
        const JsonValue & operator[] (const std::string& key) const;
        
        /** Subscript operator, access an element by index. 
            @param i index of the element to access
        */
        JsonValue & operator[] (size_t i);
    
        /** Subscript operator, access an element by index. 
            @param i index of the element to access
        */
        const JsonValue & operator[] (size_t i) const;
    
        /** Assignment operator. */
        JsonValue & operator=(const JsonValue & v);
    
        /** Move operator. */
        JsonValue & operator=(JsonValue && v);
    
        /** Cast operator for float */
        explicit operator long double() const { return float_v; }
    
        /** Cast operator for int */
        explicit operator long long int() const { return int_v; }
    
        /** Cast operator for bool */
        explicit operator bool() const { return bool_v; }
    
        /** Cast operator for string */
        explicit operator std::string () const { return string_v; }
    
        /** Cast operator for Object */
        operator JsonObject() const { return object_v; }
    
        /** Cast operator for Object */
        operator JsonArray() const { return array_v; }
        
        /** Cast operator for float */
        long double as_float() const { return float_v; }
    
        /** Cast operator for int */
        long long int as_int() const { return int_v; }
    
        /** Cast operator for bool */
        bool as_bool() const { return bool_v; }
    
        /** Cast operator for string */
        std::string as_string() const { return string_v; }


    protected:
    
        long double         float_v;
        long long int       int_v;
        bool                bool_v;
        std::string         string_v;
    
        JsonObject object_v;
        JsonArray array_v;
    
        ValueType           type_t;
    };
    
}

/** Output operator for Values */
std::ostream& operator<<(std::ostream&, const NRJSON::JsonValue &);

/** Output operator for Objects */
std::ostream& operator<<(std::ostream&, const NRJSON::JsonObject &);

/** Output operator for Arrays */
std::ostream& operator<<(std::ostream&, const NRJSON::JsonArray &);

#endif
