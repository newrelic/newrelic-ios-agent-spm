#ifndef __EventBufferConfig_H_
#define __EventBufferConfig_H_
namespace NewRelic {
 class EventBufferConfig {
 private:
     unsigned int _max_buffer_time_sec = kMaxEventBufferTimeSecDefault;
     unsigned int _max_buffer_size     = kMaxEventBufferSizeDefault;

     static EventBufferConfig* __instance;

     EventBufferConfig() = default;
 public:
     static const unsigned int kMaxEventBufferTimeSecDefault = 600;
     static const unsigned int kMaxEventBufferSizeDefault    = 1000;
     static EventBufferConfig& getInstance();
     void setMaxEventBufferTime(unsigned int);
     void setMaxEventBufferSize(unsigned int);

     unsigned int get_max_buffer_time_sec() const;

     unsigned int get_max_buffer_size() const;
 };
}

#endif // __EventBufferConfig_H_
