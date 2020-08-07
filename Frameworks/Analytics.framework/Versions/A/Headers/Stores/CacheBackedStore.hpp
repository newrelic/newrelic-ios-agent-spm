#include <iostream>
#include <string>
#include <fstream>
#include <cstdio>
#include <future>
#include <chrono>
#include <map>
#include <Analytics/Events/AnalyticEvent.hpp>
#ifndef LIBMOBILEAGENT_CACHEBACKSTORE_HPP
#define LIBMOBILEAGENT_CACHEBACKSTORE_HPP
namespace NewRelic {
    /**
     * Provide in-memory backing store for events and attribute.
     * Most specializations would derive from this class to provide cached (pre-serialized) support.
     */

    template<typename K, typename T>
    class CacheBackedStore {
    protected:
        typedef std::map<K, std::shared_ptr<T>> MAP_T;
        typedef std::shared_ptr<T> VALUE_T;

        mutable std::mutex m;
        std::map <K, VALUE_T> map;

    public:
        virtual void clear() {
            std::lock_guard<std::mutex> lk(m);
            map.clear();
        }

        virtual void store(K key, std::shared_ptr<T> obj) {
            std::lock_guard<std::mutex> lk(m);
            map[key] = obj;
        }

        virtual void remove(K key) {
            std::lock_guard<std::mutex> lk(m);
            map.erase(key);
        }

        virtual std::map <K, std::shared_ptr<T>> load() {
            std::lock_guard<std::mutex> lk(m);
            return map;
        }



    };

} // namespace NewRelic
#endif //LIBMOBILEAGENT_CACHEBACKEDSTORE_HPP
