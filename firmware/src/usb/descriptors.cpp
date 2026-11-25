#include "descriptors.hpp"
#include "usb_audio2.hpp"

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
    STRID_ADAT_OUT_CH1,
    STRID_ADAT_IN_CH1 = STRID_ADAT_OUT_CH1 + 16,
    STRID_ = STRID_ADAT_IN_CH1 + 16,
    STRID_COUNT,
};

constexpr std::array<std::string_view, STRID_COUNT> STRINGS = {
    "", // 0: language id, handled separately
    "RETHERA",
    "ADAT USB Interface",
    "", // 3: serial, generated from chip UID
    "ADAT OUT CH1",
    "ADAT OUT CH2",
    "ADAT OUT CH3",
    "ADAT OUT CH4",
    "ADAT OUT CH5",
    "ADAT OUT CH6",
    "ADAT OUT CH7",
    "ADAT OUT CH8",
    "ADAT OUT CH9",
    "ADAT OUT CH10",
    "ADAT OUT CH11",
    "ADAT OUT CH12",
    "ADAT OUT CH13",
    "ADAT OUT CH14",
    "ADAT OUT CH15",
    "ADAT OUT CH16",
    "ADAT IN CH1",
    "ADAT IN CH2",
    "ADAT IN CH3",
    "ADAT IN CH4",
    "ADAT IN CH5",
    "ADAT IN CH6",
    "ADAT IN CH7",
    "ADAT IN CH8",
    "ADAT IN CH9",
    "ADAT IN CH10",
    "ADAT IN CH11",
    "ADAT IN CH12",
    "ADAT IN CH13",
    "ADAT IN CH14",
    "ADAT IN CH15",
    "ADAT IN CH16",

    
    
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
    ITF_NUM_AUDIO_CONTROL = 0,
    ITF_NUM_AUDIO_STREAMING_OUT,
    ITF_NUM_AUDIO_STREAMING_IN,
    ITF_NUM_TOTAL,
};    uint8_t bTerminalID;


enum EntityNumber : uint8_t {
    EN_CLK48 = 0,
    EN_CLK44,
    EN_CLOCK_SELECTOR,
    EN_OUT_INPUT_TERMINAL,
    EN_OUT_FEATURE_UNIT,
    EN_OUT_OUTPUT_TERMINAL,
    EN_IN_INPUT_TERMINAL,
    EN_IN_FEATURE_UNIT,
    EN_IN_OUTPUT_TERMINAL,
    EN_TOTAL
};

enum EndpointNumber : uint8_t {
    END_AUDIO_STREAMING_IN = 0x81,
    END_AUDIO_STREAMING_OUT = 0x01,
    END_AUDIO_FEEDBACK = 0x82
};

constexpr uint8_t EPNUM_CDC_NOTIF = 0x81;
constexpr uint8_t EPNUM_CDC_OUT = 0x02;
constexpr uint8_t EPNUM_CDC_IN = 0x82;

constexpr uint16_t CONFIG_TOTAL_LEN = TUD_CONFIG_DESC_LEN + TUD_CDC_DESC_LEN;

// Full speed configuration
const uint8_t DESC_FS_CONFIGURATION[] = {
    // config number, interface count, string index, total length, attributes, power (mA)
    TUD_CONFIG_DESCRIPTOR(1, 0, 0, TUD_CONFIG_DESC_LEN, 0x00, 100),
};

const AudioInterfaceConfigurationDescriptor DESC_HS_CONFIGURATION = {
    .cd = {
        .wTotalLength = sizeof(DESC_HS_CONFIGURATION),
        .bNumInterfaces = InterfaceNumber::ITF_NUM_TOTAL,
        .bmAttributes = uac2::ConfigAttr::CONFIG_ATTR_SELF_POWERED,
        .bMaxPower = uac2::maxPowerMilliamps(500),
    },
    .iad = {
        .bFirstInterface = InterfaceNumber::ITF_NUM_AUDIO_CONTROL,
        .bInterfaceCount = InterfaceNumber::ITF_NUM_TOTAL,
        .iFunction = StringIndex::STRID_PRODUCT,
    },
    .acSid = {
        .bInterfaceNumber = InterfaceNumber::ITF_NUM_AUDIO_CONTROL,
        .bAlternateSetting = 0, //MUST BE SET TO ZERO
        .bNumEndpoints = 0, // to be changed to 1 when feedback endpoint is added
        .bInterfaceSubClass = uac2::InterfaceSubClass::AudioControl,
        .iInterface = 0,
    },
    .ac = {
        .ahd = {
            .bCategory = uac2::Category::Converter,
            .wTotalLength = sizeof(DESC_HS_CONFIGURATION.ac),
        },
        .csd48 = {
            .bClockID = EntityNumber::EN_CLK48,
            .bmAttributes = uac2::ClockAttr::CLOCK_INTERNAL_FIXED,
            .bmControls = 0,
            .bAssocTerminal = 0, // internal clock
            .iClockSource = 0,
        },
        .csd44 = {
            .bClockID = EntityNumber::EN_CLK44,
            .bmAttributes = uac2::ClockAttr::CLOCK_INTERNAL_FIXED,
            .bmControls = 0,
            .bAssocTerminal = 0, // internal clock
            .iClockSource = 0,
        },
        .csd2 = {
            .bClockID = EntityNumber::EN_CLOCK_SELECTOR,
            .baCSourceID = {EntityNumber::EN_CLK48, EntityNumber::EN_CLK44},
            .bmControls = uac2::control(uac2::Ctrl::Programmable, 0),
            .iClockSelector = 0,
        },
        .out_itd = {
            .bTerminalID = EntityNumber::EN_OUT_INPUT_TERMINAL,
            .wTerminalType = uac2::TerminalType::UsbStreaming,
            .bAssocTerminal = 0,
            .bCSourceID = EntityNumber::EN_CLOCK_SELECTOR,
            .bNrChannels = 16,
            .bmChannelConfig = 0, 
            .iChannelNames = StringIndex::STRID_ADAT_OUT_CH1,
            .bmControls = 0, //idk
            .iTerminal = 0, //idk
        },
        .out_fud16 = {
            .bUnitID = EntityNumber::EN_OUT_FEATURE_UNIT,
            .bSourceID = EntityNumber::EN_OUT_INPUT_TERMINAL,
            .bmaControls = {},
            .iFeature = 0,
        },
        .out_otd = {
            .bTerminalID = EntityNumber::EN_OUT_OUTPUT_TERMINAL,
            .wTerminalType = uac2::TerminalType::DigitalAudioInterface,
            .bAssocTerminal = 0,
            .bSourceID = EntityNumber::EN_OUT_FEATURE_UNIT,
            .bCSourceID = EntityNumber::EN_CLOCK_SELECTOR,
            .bmControls = 0,
            .iTerminal = 0,
        },
        
        .in_itd = {
            .bTerminalID = EntityNumber::EN_IN_INPUT_TERMINAL,
            .wTerminalType = uac2::TerminalType::DigitalAudioInterface,
            .bAssocTerminal = 0,
            .bCSourceID = EntityNumber::EN_CLOCK_SELECTOR,
            .bNrChannels = 16,
            .bmChannelConfig = 0, 
            .iChannelNames = StringIndex::STRID_ADAT_IN_CH1,
            .bmControls = 0, //idk
            .iTerminal = 0, //idk
        },
        .in_fud16 = {
            .bUnitID = EntityNumber::EN_IN_FEATURE_UNIT,
            .bSourceID = EntityNumber::EN_IN_INPUT_TERMINAL,
            .bmaControls = {},
            .iFeature = 0,
        },
        .in_otd = {
            .bTerminalID = EntityNumber::EN_IN_OUTPUT_TERMINAL,
            .wTerminalType = uac2::TerminalType::UsbStreaming,
            .bAssocTerminal = 0,
            .bSourceID = EntityNumber::EN_IN_FEATURE_UNIT,
            .bCSourceID = EntityNumber::EN_CLOCK_SELECTOR,
            .bmControls = 0,
            .iTerminal = 0,
        },
    },
    .out_asSid_alt0 = {
        .bInterfaceNumber = InterfaceNumber::ITF_NUM_AUDIO_STREAMING_OUT,
        .bAlternateSetting = 0,
        .bNumEndpoints = 0,
        .bInterfaceSubClass = uac2::InterfaceSubClass::AudioStreaming,
        .iInterface = 0
    },
    .out_asSid_alt1 = {
        .bInterfaceNumber = InterfaceNumber::ITF_NUM_AUDIO_STREAMING_OUT,
        .bAlternateSetting = 1,
        .bNumEndpoints = 1,
        .bInterfaceSubClass = uac2::InterfaceSubClass::AudioStreaming,
        .iInterface = 0
    },
    .out_as = {
        .agd = {
            .bTerminalLink = EntityNumber::EN_OUT_INPUT_TERMINAL,
            .bmControls = 0,
            .bNrChannels = 16,
            .iChannelNames = StringIndex::STRID_ADAT_OUT_CH1,
        },
        .ftd = {
            .bSubslotSize = 4,
            .bBitResolution = 24
        },
        .sied = {
            .bEndpointAddress = EndpointNumber::END_AUDIO_STREAMING_OUT,
            .bmAttributes = uac2::EpAttr::EP_XFER_ISOCHRONOUS | uac2::EpAttr::EP_SYNC_ASYNC | uac2::EpAttr::EP_USAGE_DATA,
            .wMaxPacketSize = 7 * 16 * 4, // 7 samples, 16 channels, 4 bytes
            .bInterval = 1,
        },
        .cied = {
 
        }
    },
    .in_asSid_alt0 = {
        .bInterfaceNumber = InterfaceNumber::ITF_NUM_AUDIO_STREAMING_IN,
        .bAlternateSetting = 0,
        .bNumEndpoints = 0,
        .bInterfaceSubClass = uac2::InterfaceSubClass::AudioStreaming,
        .iInterface = 0
    },
    .in_asSid_alt1 = {
        .bInterfaceNumber = InterfaceNumber::ITF_NUM_AUDIO_STREAMING_IN,
        .bAlternateSetting = 1,
        .bNumEndpoints = 1,
        .bInterfaceSubClass = uac2::InterfaceSubClass::AudioStreaming,
        .iInterface = 0
    },
    .in_as = {
        .agd = {
            .bTerminalLink = EntityNumber::EN_IN_OUTPUT_TERMINAL,
            .bmControls = 0,
            .bNrChannels = 16,
            .iChannelNames = StringIndex::STRID_ADAT_IN_CH1,
        },
        .ftd = {
            .bSubslotSize = 4,
            .bBitResolution = 24
        },
        .sied = {
            .bEndpointAddress = EndpointNumber::END_AUDIO_STREAMING_IN,
            .bmAttributes = uac2::EpAttr::EP_XFER_ISOCHRONOUS | uac2::EpAttr::EP_SYNC_ASYNC | uac2::EpAttr::EP_USAGE_DATA,
            .wMaxPacketSize = 7 * 16 * 4, // 7 samples, 16 channels, 4 bytes
            .bInterval = 1,
        },
        .cied = {
 
        }
    },

    

};

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

//--------------------------------------------------------------------+
// String descriptors
//--------------------------------------------------------------------+

constexpr uint16_t LANGID_EN_US = 0x0409;
constexpr size_t MAX_STRING_CHARS = 32;

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

const uint8_t* tud_descriptor_configuration_cb(uint8_t)
{

    return (tud_speed_get() == TUSB_SPEED_HIGH) ? reinterpret_cast<const uint8_t*>( &DESC_HS_CONFIGURATION) : DESC_FS_CONFIGURATION;
}

const uint8_t* tud_descriptor_device_qualifier_cb()
{
    return reinterpret_cast<const uint8_t*>(&DESC_DEVICE_QUALIFIER);
}

const uint8_t* tud_descriptor_other_speed_configuration_cb(uint8_t)
{
    static uint8_t descOtherSpeedConfig[CONFIG_TOTAL_LEN];


    const uint8_t* source = (tud_speed_get() == TUSB_SPEED_HIGH) ? DESC_FS_CONFIGURATION : reinterpret_cast<const uint8_t*>( &DESC_HS_CONFIGURATION);

    memcpy(descOtherSpeedConfig, source, CONFIG_TOTAL_LEN);
    descOtherSpeedConfig[1] = TUSB_DESC_OTHER_SPEED_CONFIG;

    return descOtherSpeedConfig;
}

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
