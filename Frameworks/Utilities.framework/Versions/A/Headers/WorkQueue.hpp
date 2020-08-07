//
// Created by Bryce Buchanan on 2/22/16.
//

#ifndef LIBMOBILEAGENT_WORKQUEUE_HPP
#define LIBMOBILEAGENT_WORKQUEUE_HPP

#include <future>
#include <queue>

namespace NewRelic {
    class WorkQueue {
    private:
        std::future<void> worker;
        std::queue<std::function<void()>> _queue;
        std::atomic_bool shouldTerminate;
        std::atomic_bool executing;
        std::condition_variable taskSignaler;
        mutable std::recursive_mutex _queueMutex;
        mutable std::mutex _threadMutex;
        bool queueReady;
        void task_thread();
    public:
        WorkQueue();
        void enqueue(std::function<void()> workItem);
        void terminate();
        virtual ~WorkQueue();
        void synchronize();
        void clearQueue();
        bool isEmpty();
    };
}

#endif //LIBMOBILEAGENT_WORKQUEUE_HPP
