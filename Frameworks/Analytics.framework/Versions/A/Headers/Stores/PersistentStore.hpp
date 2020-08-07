#include <iostream>
#include <string>
#include <sstream>
#include <fstream>
#include <cstdio>
#include <future>
#include <map>
#include <chrono>
#include <Analytics/Stores/FileBackedStore.hpp>


#ifndef LIBMOBILEAGENT_PERSISTENTSTORE_HPP
#define LIBMOBILEAGENT_PERSISTENTSTORE_HPP
namespace NewRelic {
    template<typename K, typename T>
    class PersistentStore {
    private:
        FileBackedStore<K, T> *_wrapper;

    public:
        PersistentStore(std::shared_ptr<T>(*factory)(std::istream &))
                : PersistentStore("temp", "", factory) {
        }

        PersistentStore(const char *filename, const char *sharedPath, std::shared_ptr<T>(*factory)(std::istream &)) {
            _wrapper = new FileBackedStore<K, T>(filename, sharedPath, factory);
        }

        PersistentStore(const char *filename, const char *sharedPath, std::shared_ptr<T>(*factory)(std::istream &), bool(*dataValidator)(K const& k, std::shared_ptr<T> t)) {
            _wrapper = new FileBackedStore<K, T>(filename, sharedPath, factory, dataValidator);
        }

        PersistentStore(const char *filename, const char *sharedPath) {
            _wrapper = new FileBackedStore<K, T>(filename, sharedPath);
            _wrapper->load();
        }

        virtual ~PersistentStore() {
            delete _wrapper;
        }

        virtual void clear() {
            _wrapper->clear();
        }

        virtual void store(K key, std::shared_ptr<T> obj) {
            _wrapper->store(key, obj);
        }

        virtual void remove(K key) {
            _wrapper->remove(key);
        }

        virtual std::map<K, std::shared_ptr<T>> load() {
            return _wrapper->load();
        }

        virtual void flush() {
            _wrapper->flush();
        }

        virtual std::shared_ptr<T> get(K key) {
            return _wrapper->get(key);
        }

        const char *getFullStorePath() const {
            return _wrapper->getFullStorePath();
        }

        virtual std::map<K, std::shared_ptr<T>> swap() {
            return _wrapper->swap();
        }

        virtual std::map<K, std::shared_ptr<T>> getCache() {
            return _wrapper->getCache();
        }

        //used to wait for persistent store writes to finish (used for testing)
        void synchronize() {
            _wrapper->synchronize();
        }
    };
}
#endif //LIBMOBILEAGENT_PERSISTENTSTORE_HPP
