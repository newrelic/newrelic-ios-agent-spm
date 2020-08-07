#include <unistd.h>
#include "CacheBackedStore.hpp"
#include <Utilities/libLogger.hpp>
#include <Utilities/WorkQueue.hpp>
#include <Analytics/Events/AnalyticEvent.hpp>
#include <chrono>
#include <sstream>


#ifndef LIBMOBILEAGENT_FILEBACKEDSTORE_HPP
#define LIBMOBILEAGENT_FILEBACKEDSTORE_HPP
namespace NewRelic {
template<typename K, typename T>
class FileBackedStore : public CacheBackedStore<K, T> {

private:
    const char* BACKUP_SUFFIX = ".bak";
    mutable std::mutex _fileMutex;
    std::ofstream _fO;
    std::string _fullPath;

    std::shared_ptr<T> (* _factory)(std::istream&) = &FileBackedStore::read;

    bool (* _validator)(K const& k,
                        std::shared_ptr<T> t);

    std::chrono::time_point<std::chrono::system_clock> lastWriteTime;
    bool dirtyFlag = false;
    WorkQueue workQueue;

public:
    static const inline std::chrono::time_point<std::chrono::system_clock>::duration writeThrottle() {
        return std::chrono::milliseconds(25);
    }

    FileBackedStore() : FileBackedStore("temp") {}

    FileBackedStore(const char* filename) : FileBackedStore(filename, "") {}

    FileBackedStore(const char* filename,
                    const char* sharedPath)
            : FileBackedStore(filename, sharedPath, &FileBackedStore::read) {}

    FileBackedStore(const char* filename,
                    const char* sharedPath,
                    std::shared_ptr<T>(* factory)(std::istream&))
            : FileBackedStore(filename, sharedPath, factory, [](K const& k,
                                                                std::shared_ptr<T> t) { return true; }) {}

    FileBackedStore(const char* filename,
                    const char* sharedPath,
                    std::shared_ptr<T>(* factory)(std::istream&),
                    bool(* validator)(K const&,
                                      std::shared_ptr<T>))
            : CacheBackedStore<K, T>(),
              _fO{},
              _fullPath(getFullPath(sharedPath, filename)),
              _factory(factory),
              _validator(validator),
              lastWriteTime(),
              workQueue() {
        loadFromFile();
        clearBackup();
    };

    void synchronize() {
        workQueue.synchronize();
    }


    virtual ~FileBackedStore() {

        workQueue.terminate();
        std::lock_guard<std::mutex> lk(_fileMutex);
        if (dirtyFlag) {
            flush();
        }
        if (_fO.is_open())
            _fO.close();
    }

    virtual void clear() {
        CacheBackedStore<K, T>::clear();
        workQueue.enqueue([this] {
            try {
                std::lock_guard<std::mutex> lk(_fileMutex);
                _fO.close();
                _fO.open(_fullPath, std::ios::trunc);
                _fO.rdbuf()->pubsetbuf(0, 0);
            } catch (std::exception& e) {
                LLOG_VERBOSE("failed to clear file: %s\nreason: %s", _fullPath.c_str(), e.what());
            } catch (...) {
                LLOG_VERBOSE("Failed to clear file: %s", _fullPath.c_str());
            }
        });
    }

    virtual void store(K key,
                       std::shared_ptr<T> obj) {
        CacheBackedStore<K, T>::store(key, obj);
        dirtyFlag = true;
        workQueue.enqueue([this] {
            try {
                // if it hasn't been long enough sleep?
                if (std::chrono::system_clock::now() - lastWriteTime < writeThrottle()) {
                    std::this_thread::sleep_for(writeThrottle());
                }

                std::lock_guard<std::mutex> lk(_fileMutex);
                flush();
            } catch (std::exception& e) {
                LLOG_VERBOSE("Failed to store item: %s", e.what());
            } catch (...) {
                LLOG_VERBOSE("Failed to store item.");
            }
        });
    }

    virtual void remove(K key) {
        CacheBackedStore<K, T>::remove(key);
        dirtyFlag = true;
        workQueue.enqueue([this] {
            try {
                std::lock_guard<std::mutex> lk(_fileMutex);
                flush();
            } catch (std::exception& e) {
                LLOG_VERBOSE("Failed to remove item: %s", e.what());
            } catch (...) {
                LLOG_VERBOSE("Failed to remove item.");
            }
        });
    }

    virtual std::map<K, std::shared_ptr<T>> load() {
        std::lock_guard<std::mutex> lk(_fileMutex);
        CacheBackedStore<K, T>::clear();
        loadFromFile();
        return CacheBackedStore<K, T>::map;
    }

    virtual void flush() {
        writeToFile();
    }

    virtual std::shared_ptr<T> get(K key) {
        auto map = CacheBackedStore<K, T>::map;
        return map[key];
    }

    virtual const char* getFullStorePath() const {
        return _fullPath.c_str();
    }

    const std::map<K, std::shared_ptr<T>> swap() {
        std::lock_guard<std::mutex> flk(_fileMutex);
        std::lock_guard<std::mutex> lk(CacheBackedStore<K, T>::m);
        if (_fO.is_open()) {
            _fO.flush();
            _fO.close();
        }

        std::string backupStorePath = std::string(getFullStorePath()) + BACKUP_SUFFIX;
        auto result = rename(getFullStorePath(), backupStorePath.c_str());
        if (result == 0) {
            _fO.open(_fullPath, std::ios::trunc);
            _fO.rdbuf()->pubsetbuf(0, 0);
        } else {
            LLOG_VERBOSE("failed to create backup store: %s", backupStorePath.c_str());
        }

        // save cache data as return result, but clear the internal cache
        auto map = getCache();
        CacheBackedStore<K, T>::map.clear();

        return map;
    }

    virtual std::map<K, std::shared_ptr<T>> getCache() {
        return CacheBackedStore<K, T>::map;
    }

protected:
    static std::shared_ptr<T> read(std::istream& is) {
        std::shared_ptr<T> t = std::make_shared<T>();
        is >> (*t);
        return t;
    }

    void loadFromFile() {
        std::ifstream _fI;
        std::string key;
        std::string value;

        std::lock_guard<std::mutex> lk(CacheBackedStore<K, T>::m);
        _fI.open(_fullPath);
        const std::streamoff offset = std::streamoff(0);
        _fI.seekg(offset, std::ios_base::beg);

        try {
            while (std::getline(_fI, key)) {
                std::getline(_fI, value);
                K k{key};
                std::stringstream is{value};

                std::shared_ptr<T> t = _factory(is);
                if (_validator(k, t)) {
                    CacheBackedStore<K, T>::map[k] = t;
                }
            }
        } catch (...) {
            const std::streamoff offset = std::streamoff(0);
            _fI.seekg(offset, std::ios_base::beg);
            CacheBackedStore<K, T>::map.clear();
        }
        _fI.close();
        dirtyFlag = false;
    }

    void writeToFile() {
        std::lock_guard<std::mutex> lk(CacheBackedStore<K, T>::m);
        auto map = CacheBackedStore<K, T>::map;

        if (dirtyFlag) {
            if (!_fO.is_open()) {
                _fO.open(_fullPath);
                _fO.rdbuf()->pubsetbuf(0, 0);
            }

            _fO.seekp(0);
            for (auto it = map.cbegin(); it != map.cend(); it++) {
                _fO << it->first << std::endl << std::flush;
                _fO << *(it->second) << std::endl << std::flush;
            }
            _fO.flush();

            // Update the file meta with real size, to exclude lingering data
            auto rc = truncate(getFullStorePath(), _fO.tellp());
            if (-1 == rc) {
                LLOG_VERBOSE("File truncation failed on \"%s\". Errno: %d", getFullStorePath(), errno);
            }

            dirtyFlag = false;
            lastWriteTime = std::chrono::system_clock::now();
        }

    }

protected:

    virtual std::string getFullPath(std::string filePath,
                                    std::string fileName) {
        if (filePath.length() > 0) {
            return filePath + "/" + fileName;
        } else {
            return fileName;
        }
    }

    void clearBackup() {
        std::string backupStorePath = std::string(getFullStorePath()) + BACKUP_SUFFIX;
        std::remove(backupStorePath.c_str());
    }
};
} // namespace NewRelic

#endif // LIBMOBILEAGENT_FILEBACKEDSTORE_HPP

