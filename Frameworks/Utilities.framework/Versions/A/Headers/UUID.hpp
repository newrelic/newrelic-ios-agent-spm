//
//

#ifndef LIBMOBILEAGENT_UUID_HPP
#define LIBMOBILEAGENT_UUID_HPP

#include <string>
#include <random>
namespace NewRelic {

//uuid version 4 (http://www.ietf.org/rfc/rfc4122.txt)
/*
 * * The algorithm is as follows:

   o  Set the two most significant bits (bits 6 and 7) of the
      clock_seq_hi_and_reserved to zero and one, respectively.

   o  Set the four most significant bits (bits 12 through 15) of the
      time_hi_and_version field to the 4-bit version number from
      Section 4.1.3.

   o  Set all the other bits to randomly (or pseudo-randomly) chosen
      values.


     Implemented in little endian format.
 */

class UUID {
protected:


    uint32_t time_low            = 0;
    uint16_t time_mid            = 0;
    uint16_t time_hi_and_version = kUUID_VERSION; // initialize version (step 2)
    uint16_t clk_seq             = 1 << 15; // initialize (step 1)
    uint16_t node0_1             = 0;
    uint32_t node2_5             = 0;


    UUID() = default;

    static UUID createUUID(std::function<uint32_t()> randomNumberGenerator);
public:

    static UUID createUUID();
    std::string toString();

    //accessors
    uint32_t getTime_low() const;

    uint16_t getTime_mid() const;

    uint16_t getTime_hi_and_version() const;

    uint16_t getClk_seq() const;

    uint16_t getNode0_1() const;

    uint32_t getNode2_5() const;

    static const uint16_t kTIME_BIT_MASK    = 0x0FFF;
    static const uint16_t kCLK_SEQ_BIT_MASK = 0x3FFF;
    static const uint16_t kUUID_VERSION     = 0x4000;
};
} // namespace NewRelic
#endif //LIBMOBILEAGENT_UUID_HPP
