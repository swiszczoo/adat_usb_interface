#include <stm32f4xx.h>
#include <tusb.h>

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <string_view>

namespace {

//--------------------------------------------------------------------+
// Device descriptor
//--------------------------------------------------------------------+

// Placeholder VID/PID (pid.codes test range), replace before release
constexpr uint16_t USB_VID = 0x1209;
constexpr uint16_t USB_PID = 0x0001;
constexpr uint16_t USB_BCD = 0x0200;

enum StringIndex : uint8_t {
    STRID_LANGID = 0,
    STRID_MANUFACTURER,
    STRID_PRODUCT,
    STRID_SERIAL,
    STRID_CDC,
    STRID_COUNT,
};

const tusb_desc_device_t DESC_DEVICE = {
    .bLength = sizeof(tusb_desc_device_t),
    .bDescriptorType = TUSB_DESC_DEVICE,
    .bcdUSB = USB_BCD,

    // IAD, required for CDC / UAC2 composite device
    .bDeviceClass = TUSB_CLASS_MISC,
    .bDeviceSubClass = MISC_SUBCLASS_COMMON,
    .bDeviceProtocol = MISC_PROTOCOL_IAD,

    .bMaxPacketSize0 = CFG_TUD_ENDPOINT0_SIZE,
    .idVendor = USB_VID,
    .idProduct = USB_PID,
    .bcdDevice = 0x0100,

    .iManufacturer = STRID_MANUFACTURER,
    .iProduct = STRID_PRODUCT,
    .iSerialNumber = STRID_SERIAL,

    .bNumConfigurations = 0x01,
};

//--------------------------------------------------------------------+
// Configuration descriptor
//--------------------------------------------------------------------+

enum InterfaceNumber : uint8_t {
    ITF_NUM_CDC = 0,
    ITF_NUM_CDC_DATA,
    ITF_NUM_TOTAL,
};

constexpr uint8_t EPNUM_CDC_NOTIF = 0x81;
constexpr uint8_t EPNUM_CDC_OUT = 0x02;
constexpr uint8_t EPNUM_CDC_IN = 0x82;

constexpr uint16_t CONFIG_TOTAL_LEN = TUD_CONFIG_DESC_LEN + TUD_CDC_DESC_LEN;

// Full speed configuration
const uint8_t DESC_FS_CONFIGURATION[] = {
    // config number, interface count, string index, total length, attributes, power (mA)
    TUD_CONFIG_DESCRIPTOR(1, ITF_NUM_TOTAL, 0, CONFIG_TOTAL_LEN, 0x00, 100),

    // interface number, string index, notif EP, notif EP size, EP OUT, EP IN, EP size
    TUD_CDC_DESCRIPTOR(ITF_NUM_CDC, STRID_CDC, EPNUM_CDC_NOTIF, 8, EPNUM_CDC_OUT, EPNUM_CDC_IN, 64),
};

#if TUD_OPT_HIGH_SPEED
// High speed configuration
const uint8_t DESC_HS_CONFIGURATION[] = {
    TUD_CONFIG_DESCRIPTOR(1, ITF_NUM_TOTAL, 0, CONFIG_TOTAL_LEN, 0x00, 100),
    TUD_CDC_DESCRIPTOR(ITF_NUM_CDC, STRID_CDC, EPNUM_CDC_NOTIF, 16, EPNUM_CDC_OUT, EPNUM_CDC_IN, 512),
};

static_assert(sizeof(DESC_FS_CONFIGURATION) == CONFIG_TOTAL_LEN);
static_assert(sizeof(DESC_HS_CONFIGURATION) == CONFIG_TOTAL_LEN);

// Other speed configuration buffer (descriptor type differs from regular configuration)
uint8_t descOtherSpeedConfig[CONFIG_TOTAL_LEN];

// Device qualifier, required for high speed capable devices
const tusb_desc_device_qualifier_t DESC_DEVICE_QUALIFIER = {
    .bLength = sizeof(tusb_desc_device_qualifier_t),
    .bDescriptorType = TUSB_DESC_DEVICE_QUALIFIER,
    .bcdUSB = USB_BCD,

    .bDeviceClass = TUSB_CLASS_MISC,
    .bDeviceSubClass = MISC_SUBCLASS_COMMON,
    .bDeviceProtocol = MISC_PROTOCOL_IAD,

    .bMaxPacketSize0 = CFG_TUD_ENDPOINT0_SIZE,
    .bNumConfigurations = 0x01,
    .bReserved = 0x00,
};
#endif

//--------------------------------------------------------------------+
// String descriptors
//--------------------------------------------------------------------+

constexpr uint16_t LANGID_EN_US = 0x0409;
constexpr size_t MAX_STRING_CHARS = 32;

constexpr std::array<std::string_view, STRID_COUNT> STRINGS = {
    "", // 0: language id, handled separately
    "swiszczoo",
    "ADAT USB Interface",
    "", // 3: serial, generated from chip UID
    "Debug CDC",
};

uint16_t descString[MAX_STRING_CHARS + 1];

size_t writeSerialNumber(uint16_t* out)
{
    const auto* uid = reinterpret_cast<const uint32_t*>(UID_BASE);
    constexpr char HEX[] = "0123456789ABCDEF";

    size_t count = 0;
    for (size_t word = 0; word < 3; ++word) {
        uint32_t value = uid[word];
        for (int shift = 28; shift >= 0; shift -= 4) {
            out[count++] = HEX[(value >> shift) & 0xF];
        }
    }

    return count;
}

}

//--------------------------------------------------------------------+
// TinyUSB callbacks
//--------------------------------------------------------------------+

const uint8_t* tud_descriptor_device_cb()
{
    return reinterpret_cast<const uint8_t*>(&DESC_DEVICE);
}

const uint8_t* tud_descriptor_configuration_cb(uint8_t index)
{
    (void)index;

#if TUD_OPT_HIGH_SPEED
    return (tud_speed_get() == TUSB_SPEED_HIGH) ? DESC_HS_CONFIGURATION : DESC_FS_CONFIGURATION;
#else
    return DESC_FS_CONFIGURATION;
#endif
}

#if TUD_OPT_HIGH_SPEED
const uint8_t* tud_descriptor_device_qualifier_cb()
{
    return reinterpret_cast<const uint8_t*>(&DESC_DEVICE_QUALIFIER);
}

const uint8_t* tud_descriptor_other_speed_configuration_cb(uint8_t index)
{
    (void)index;

    // Report the configuration of the speed we are NOT currently running at
    const uint8_t* source = (tud_speed_get() == TUSB_SPEED_HIGH) ? DESC_FS_CONFIGURATION : DESC_HS_CONFIGURATION;

    memcpy(descOtherSpeedConfig, source, CONFIG_TOTAL_LEN);
    descOtherSpeedConfig[1] = TUSB_DESC_OTHER_SPEED_CONFIG;

    return descOtherSpeedConfig;
}
#endif

const uint16_t* tud_descriptor_string_cb(uint8_t index, uint16_t langid)
{
    (void)langid;
    size_t charCount = 0;

    if (index == STRID_LANGID) {
        descString[1] = LANGID_EN_US;
        charCount = 1;
    } else if (index == STRID_SERIAL) {
        charCount = writeSerialNumber(&descString[1]);
    } else {
        if (index >= STRINGS.size()) {
            return nullptr;
        }

        const auto& str = STRINGS[index];
        charCount = std::min(str.size(), MAX_STRING_CHARS);

        // ASCII -> UTF-16
        for (size_t i = 0; i < charCount; ++i) {
            descString[1 + i] = static_cast<uint8_t>(str[i]);
        }
    }

    descString[0] = static_cast<uint16_t>((TUSB_DESC_STRING << 8) | (2 * charCount + 2));
    return descString;
}
