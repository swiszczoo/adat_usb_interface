// USB Audio Class 2.0 descriptor structures and enums.
//
// Source: "USB Device Class Definition for Audio Devices", Release 2.0
// (docs/Audio2_with_Errata_and_ECN_through_Apr_2_2025.pdf). Table / appendix
// numbers in comments refer to that document, except where noted as coming
// from the separate "Audio Data Formats" / "Terminal Types" documents.
//
// Only the descriptors needed for a device with
//   - clock sources (e.g. 48 kHz / 44.1 kHz) + one clock selector
//   - N-channel USB streaming in / out (Input/Output terminals)
//   - a feature unit
//   - an isochronous data endpoint + isochronous feedback endpoint
// are defined. All structs are packed, little-endian (Cortex-M), and sized to
// match the on-the-wire layout so they can be brace-initialised by hand and
// embedded in a configuration descriptor blob.

#pragma once

#include <cstddef>
#include <cstdint>

namespace uac2 {

//--------------------------------------------------------------------+
// Enums (Appendix A)
//--------------------------------------------------------------------+

// A.1 - A.6
enum class FunctionClass : uint8_t { Audio = 0x01 };           // bFunctionClass
enum class FunctionSubClass : uint8_t { Undefined = 0x00 };    // bFunctionSubClass
enum class FunctionProtocol : uint8_t {                        // bFunctionProtocol
    Undefined = 0x00,
    Version_02_00 = 0x20,  // AF_VERSION_02_00 == IP_VERSION_02_00
};
enum class InterfaceClass : uint8_t { Audio = 0x01 };         // bInterfaceClass
enum class InterfaceSubClass : uint8_t {                      // bInterfaceSubClass
    Undefined = 0x00,
    AudioControl = 0x01,
    AudioStreaming = 0x02,
    MidiStreaming = 0x03,
};
enum class InterfaceProtocol : uint8_t {                      // bInterfaceProtocol
    Undefined = 0x00,
    Version_02_00 = 0x20,
};

// A.7 Function category (bCategory in AC header)
enum class Category : uint8_t {
    Undefined = 0x00,
    DesktopSpeaker = 0x01,
    HomeTheater = 0x02,
    Microphone = 0x03,
    Headset = 0x04,
    Telephone = 0x05,
    Converter = 0x06,
    VoiceSoundRecorder = 0x07,
    IoBox = 0x08,
    MusicalInstrument = 0x09,
    ProAudio = 0x0A,
    AudioVideo = 0x0B,
    ControlPanel = 0x0C,
    Other = 0xFF,
};

// Standard USB descriptor types used by audio
enum class StdDescriptorType : uint8_t {
    Configuration = 0x02,
    Interface = 0x04,
    Endpoint = 0x05,
    InterfaceAssociation = 0x0B,
};

// A.8 Class-specific descriptor types (bDescriptorType)
enum class CsDescriptorType : uint8_t {
    Undefined = 0x20,
    Device = 0x21,
    Configuration = 0x22,
    String = 0x23,
    Interface = 0x24,  // CS_INTERFACE
    Endpoint = 0x25,   // CS_ENDPOINT
};

// A.9 Class-specific AC interface descriptor subtypes
enum class AcSubtype : uint8_t {
    Undefined = 0x00,
    Header = 0x01,
    InputTerminal = 0x02,
    OutputTerminal = 0x03,
    MixerUnit = 0x04,
    SelectorUnit = 0x05,
    FeatureUnit = 0x06,
    EffectUnit = 0x07,
    ProcessingUnit = 0x08,
    ExtensionUnit = 0x09,
    ClockSource = 0x0A,
    ClockSelector = 0x0B,
    ClockMultiplier = 0x0C,
    SampleRateConverter = 0x0D,
};

// A.10 Class-specific AS interface descriptor subtypes
enum class AsSubtype : uint8_t {
    Undefined = 0x00,
    General = 0x01,     // AS_GENERAL
    FormatType = 0x02,  // FORMAT_TYPE
    Encoder = 0x03,
    Decoder = 0x04,
};

// A.13 Class-specific endpoint descriptor subtypes
enum class EpSubtype : uint8_t {
    Undefined = 0x00,
    General = 0x01,  // EP_GENERAL
};

// A.14 Class-specific request codes (bRequest)
enum class Request : uint8_t {
    Undefined = 0x00,
    Cur = 0x01,
    Range = 0x02,
    Mem = 0x03,
};

// A.17 Control selectors (high byte of wValue)
enum class ClockSourceControl : uint8_t {
    Undefined = 0x00,
    SamFreq = 0x01,      // CS_SAM_FREQ_CONTROL
    ClockValid = 0x02,   // CS_CLOCK_VALID_CONTROL
};
enum class ClockSelectorControl : uint8_t {
    Undefined = 0x00,
    ClockSelector = 0x01,  // CX_CLOCK_SELECTOR_CONTROL
};
enum class FeatureUnitControl : uint8_t {
    Undefined = 0x00,
    Mute = 0x01,
    Volume = 0x02,
    Bass = 0x03,
    Mid = 0x04,
    Treble = 0x05,
    GraphicEqualizer = 0x06,
    AutomaticGain = 0x07,
    Delay = 0x08,
    BassBoost = 0x09,
    Loudness = 0x0A,
    InputGain = 0x0B,
    InputGainPad = 0x0C,
    PhaseInverter = 0x0D,
    Underflow = 0x0E,
    Overflow = 0x0F,
    Latency = 0x10,
    HighpassFilter = 0x11,
};
enum class AsControl : uint8_t {
    Undefined = 0x00,
    ActAltSetting = 0x01,
    ValAltSettings = 0x02,
    AudioDataFormat = 0x03,
};
enum class EpControl : uint8_t {
    Undefined = 0x00,
    Pitch = 0x01,
    DataOverrun = 0x02,
    DataUnderrun = 0x03,
};

//--------------------------------------------------------------------+
// Bitmaps / field values
//--------------------------------------------------------------------+

// Control bit pairs (used in every bmControls / bmaControls field):
//   0b00 not present, 0b01 present read-only, 0b11 present and host-programmable
// (0b10 is illegal). Helper returns the pair shifted into position `index`
// (0 = D1..0, 1 = D3..2, ...).
enum class Ctrl : uint8_t {
    None = 0b00,
    ReadOnly = 0b01,
    Programmable = 0b11,
};
constexpr uint32_t control(Ctrl c, unsigned index) {
    return static_cast<uint32_t>(c) << (index * 2);
}

// Table 4-6 bmAttributes: D1..0 clock type, D2 sync to SOF
enum ClockAttr : uint8_t {
    CLOCK_EXTERNAL = 0b000,
    CLOCK_INTERNAL_FIXED = 0b001,
    CLOCK_INTERNAL_VARIABLE = 0b010,
    CLOCK_INTERNAL_PROGRAMMABLE = 0b011,
    CLOCK_SYNC_TO_SOF = 1u << 2,
};

// Table 4-6 bmControls: bit pair 0 = frequency, bit pair 1 = validity
constexpr uint8_t clockSourceControls(Ctrl freq, Ctrl valid) {
    return static_cast<uint8_t>(control(freq, 0) | control(valid, 1));
}

// Table 4-13 Feature Unit bmaControls (32-bit per channel), bit pair index:
enum FeatureUnitControlIdx : unsigned {
    FU_IDX_MUTE = 0,
    FU_IDX_VOLUME = 1,
    FU_IDX_BASS = 2,
    FU_IDX_MID = 3,
    FU_IDX_TREBLE = 4,
    FU_IDX_GRAPHIC_EQ = 5,
    FU_IDX_AGC = 6,
    FU_IDX_DELAY = 7,
    FU_IDX_BASS_BOOST = 8,
    FU_IDX_LOUDNESS = 9,
    FU_IDX_INPUT_GAIN = 10,
    FU_IDX_INPUT_GAIN_PAD = 11,
    FU_IDX_PHASE_INVERTER = 12,
    FU_IDX_UNDERFLOW = 13,
    FU_IDX_OVERFLOW = 14,
    FU_IDX_LATENCY = 15,  // present in spec release 2.0 errata, check device support
};

// Table 4-9 / 4-10 terminal bmControls bit-pair indices
enum InputTerminalControlIdx : unsigned {
    IT_IDX_COPY_PROTECT = 0,
    IT_IDX_CONNECTOR = 1,
    IT_IDX_OVERLOAD = 2,
    IT_IDX_CLUSTER = 3,
    IT_IDX_UNDERFLOW = 4,
    IT_IDX_OVERFLOW = 5,
};
enum OutputTerminalControlIdx : unsigned {
    OT_IDX_COPY_PROTECT = 0,
    OT_IDX_CONNECTOR = 1,
    OT_IDX_OVERLOAD = 2,
    OT_IDX_UNDERFLOW = 3,
    OT_IDX_OVERFLOW = 4,
};

// Table 4-5 AC header bmControls: D1..0 latency control
// Table 4-27 AS general bmControls: D1..0 active alt setting, D3..2 valid alt settings
constexpr uint8_t asGeneralControls(Ctrl activeAlt, Ctrl validAlt) {
    return static_cast<uint8_t>(control(activeAlt, 0) | control(validAlt, 1));
}

// Terminal types (wTerminalType). These come from the separate
// "USB Audio Device Class Terminal Types" document, NOT the PDF in docs/.
enum class TerminalType : uint16_t {
    Undefined = 0x0100,
    UsbStreaming = 0x0101,
    UsbVendorSpecific = 0x01FF,
    // External connectors
    LineConnector = 0x0603,
    DigitalAudioInterface = 0x0602,
    SpdifInterface = 0x0605,
    // 0x06xx / 0x07xx etc. — add as required
};

// Spatial location bitmap (bmChannelConfig). 0 = no spatial position
// ("raw" / unnamed channels), which is what you want for a 16-ch interface.
constexpr uint32_t CHANNEL_CONFIG_NONE = 0;

// Table 4-27 bFormatType / Formats doc
enum class FormatType : uint8_t {
    Undefined = 0x00,
    I = 0x01,
    II = 0x02,
    III = 0x03,
    IV = 0x04,
};

// bmFormats in AS_GENERAL for Format Type I (Formats doc, Table A-2)
enum TypeIFormat : uint32_t {
    FORMAT_I_PCM = 1u << 0,
    FORMAT_I_PCM8 = 1u << 1,
    FORMAT_I_IEEE_FLOAT = 1u << 2,
    FORMAT_I_ALAW = 1u << 3,
    FORMAT_I_MULAW = 1u << 4,
    FORMAT_I_RAW_DATA = 1u << 31,
};

// Endpoint bmAttributes (Table 4-33 / 4-35), USB transfer type / sync / usage
enum EpAttr : uint8_t {
    EP_XFER_ISOCHRONOUS = 0b01,
    EP_SYNC_NONE = 0b00 << 2,
    EP_SYNC_ASYNC = 0b01 << 2,
    EP_SYNC_ADAPTIVE = 0b10 << 2,
    EP_SYNC_SYNCHRONOUS = 0b11 << 2,
    EP_USAGE_DATA = 0b00 << 4,
    EP_USAGE_FEEDBACK = 0b01 << 4,
    EP_USAGE_IMPLICIT_FB_DATA = 0b10 << 4,
};

// Table 4-34 bmAttributes of CS endpoint
enum CsEpAttr : uint8_t {
    CS_EP_MAX_PACKETS_ONLY = 1u << 7,
};

// Table 4-34 bLockDelayUnits
enum class LockDelayUnits : uint8_t {
    Undefined = 0,
    Milliseconds = 1,
    DecodedPcmSamples = 2,
};

// USB 2.0 Table 9-10 configuration bmAttributes (bit 7 is reserved, must be 1)
enum ConfigAttr : uint8_t {
    CONFIG_ATTR_RESERVED_ONE = 1u << 7,
    CONFIG_ATTR_SELF_POWERED = 1u << 6,
    CONFIG_ATTR_REMOTE_WAKEUP = 1u << 5,
};

// bMaxPower is in units of 2 mA (high-speed and full-speed)
constexpr uint8_t maxPowerMilliamps(unsigned mA) {
    return static_cast<uint8_t>(mA / 2);
}

//--------------------------------------------------------------------+
// Descriptor structures
//--------------------------------------------------------------------+

#pragma pack(push, 1)

// Standard USB Configuration Descriptor (USB 2.0 Table 9-10, 9 bytes)
// wTotalLength = this header + everything that follows in the configuration
// (IADs, interfaces, class-specific and endpoint descriptors).
struct ConfigurationDescriptor {
    uint8_t bLength = sizeof(ConfigurationDescriptor);
    StdDescriptorType bDescriptorType = StdDescriptorType::Configuration;
    uint16_t wTotalLength;
    uint8_t bNumInterfaces;
    uint8_t bConfigurationValue = 1;
    uint8_t iConfiguration = 0;
    uint8_t bmAttributes = CONFIG_ATTR_RESERVED_ONE;  // ConfigAttr bits
    uint8_t bMaxPower;  // maxPowerMilliamps()
};
static_assert(sizeof(ConfigurationDescriptor) == 9);

// Table 4-3 Standard Interface Association Descriptor (8 bytes)
struct InterfaceAssociationDescriptor {
    uint8_t bLength = sizeof(InterfaceAssociationDescriptor);
    StdDescriptorType bDescriptorType = StdDescriptorType::InterfaceAssociation;
    uint8_t bFirstInterface;
    uint8_t bInterfaceCount;
    FunctionClass bFunctionClass = FunctionClass::Audio;
    FunctionSubClass bFunctionSubClass = FunctionSubClass::Undefined;
    FunctionProtocol bFunctionProtocol = FunctionProtocol::Version_02_00;
    uint8_t iFunction;
};
static_assert(sizeof(InterfaceAssociationDescriptor) == 8);

// Table 4-4 Standard AC Interface Descriptor (9 bytes)
// Table 4-26 Standard AS Interface Descriptor (9 bytes)  -- identical layout,
// only bInterfaceSubClass differs.
struct StandardInterfaceDescriptor {
    uint8_t bLength = sizeof(StandardInterfaceDescriptor);
    StdDescriptorType bDescriptorType = StdDescriptorType::Interface;
    uint8_t bInterfaceNumber;
    uint8_t bAlternateSetting;
    uint8_t bNumEndpoints;
    InterfaceClass bInterfaceClass = InterfaceClass::Audio;
    InterfaceSubClass bInterfaceSubClass;  // AudioControl or AudioStreaming
    InterfaceProtocol bInterfaceProtocol = InterfaceProtocol::Version_02_00;
    uint8_t iInterface;
};
static_assert(sizeof(StandardInterfaceDescriptor) == 9);

// Table 4-5 Class-Specific AC Interface Header Descriptor (9 bytes)
// wTotalLength = this header + all clock/unit/terminal descriptors.
struct AcHeaderDescriptor {
    uint8_t bLength = sizeof(AcHeaderDescriptor);
    CsDescriptorType bDescriptorType = CsDescriptorType::Interface;
    AcSubtype bDescriptorSubtype = AcSubtype::Header;
    uint16_t bcdADC = 0x0200;
    Category bCategory;
    uint16_t wTotalLength;
    uint8_t bmControls = 0;  // D1..0 latency control
};
static_assert(sizeof(AcHeaderDescriptor) == 9);

// Table 4-6 Clock Source Descriptor (8 bytes)
struct ClockSourceDescriptor {
    uint8_t bLength = sizeof(ClockSourceDescriptor);
    CsDescriptorType bDescriptorType = CsDescriptorType::Interface;
    AcSubtype bDescriptorSubtype = AcSubtype::ClockSource;
    uint8_t bClockID;
    uint8_t bmAttributes;  // ClockAttr bits
    uint8_t bmControls;    // clockSourceControls()
    uint8_t bAssocTerminal;
    uint8_t iClockSource;
};
static_assert(sizeof(ClockSourceDescriptor) == 8);

// Table 4-7 Clock Selector Descriptor (7 + p bytes). p = number of input pins.
template <uint8_t P>
struct ClockSelectorDescriptor {
    uint8_t bLength = sizeof(ClockSelectorDescriptor);
    CsDescriptorType bDescriptorType = CsDescriptorType::Interface;
    AcSubtype bDescriptorSubtype = AcSubtype::ClockSelector;
    uint8_t bClockID;
    uint8_t bNrInPins = P;
    uint8_t baCSourceID[P];
    uint8_t bmControls;  // D1..0 clock selector control
    uint8_t iClockSelector;
};
static_assert(sizeof(ClockSelectorDescriptor<2>) == 7 + 2);

// Table 4-9 Input Terminal Descriptor (17 bytes)
struct InputTerminalDescriptor {
    uint8_t bLength = sizeof(InputTerminalDescriptor);
    CsDescriptorType bDescriptorType = CsDescriptorType::Interface;
    AcSubtype bDescriptorSubtype = AcSubtype::InputTerminal;
    uint8_t bTerminalID;
    TerminalType wTerminalType;
    uint8_t bAssocTerminal;
    uint8_t bCSourceID;  // clock entity (selector) feeding this terminal
    uint8_t bNrChannels;
    uint32_t bmChannelConfig;
    uint8_t iChannelNames;
    uint16_t bmControls;  // see InputTerminalControlIdx
    uint8_t iTerminal;
};
static_assert(sizeof(InputTerminalDescriptor) == 17);

// Table 4-10 Output Terminal Descriptor (12 bytes)
struct OutputTerminalDescriptor {
    uint8_t bLength = sizeof(OutputTerminalDescriptor);
    CsDescriptorType bDescriptorType = CsDescriptorType::Interface;
    AcSubtype bDescriptorSubtype = AcSubtype::OutputTerminal;
    uint8_t bTerminalID;
    TerminalType wTerminalType;
    uint8_t bAssocTerminal;
    uint8_t bSourceID;   // unit/terminal feeding this terminal
    uint8_t bCSourceID;  // clock entity
    uint16_t bmControls;  // see OutputTerminalControlIdx
    uint8_t iTerminal;
};
static_assert(sizeof(OutputTerminalDescriptor) == 12);

// Table 4-13 Feature Unit Descriptor (6 + (ch+1)*4 bytes)
// bmaControls[0] is the master channel, [1..ch] the logical channels.
template <uint8_t Channels>
struct FeatureUnitDescriptor {
    uint8_t bLength = sizeof(FeatureUnitDescriptor);
    CsDescriptorType bDescriptorType = CsDescriptorType::Interface;
    AcSubtype bDescriptorSubtype = AcSubtype::FeatureUnit;
    uint8_t bUnitID;
    uint8_t bSourceID;
    uint32_t bmaControls[Channels + 1];
    uint8_t iFeature;
};
static_assert(sizeof(FeatureUnitDescriptor<16>) == 6 + (16 + 1) * 4);

// Table 4-27 Class-Specific AS Interface Descriptor (16 bytes)
struct AsGeneralDescriptor {
    uint8_t bLength = sizeof(AsGeneralDescriptor);
    CsDescriptorType bDescriptorType = CsDescriptorType::Interface;
    AsSubtype bDescriptorSubtype = AsSubtype::General;
    uint8_t bTerminalLink;
    uint8_t bmControls;  // asGeneralControls()
    FormatType bFormatType = FormatType::I;
    uint32_t bmFormats = FORMAT_I_PCM;
    uint8_t bNrChannels;
    uint32_t bmChannelConfig = CHANNEL_CONFIG_NONE;
    uint8_t iChannelNames;
};
static_assert(sizeof(AsGeneralDescriptor) == 16);

// Format Type I Descriptor (6 bytes) — Audio Data Formats 2.0, Table 2-2
// (not in the Audio2 PDF).
struct FormatTypeIDescriptor {
    uint8_t bLength = sizeof(FormatTypeIDescriptor);
    CsDescriptorType bDescriptorType = CsDescriptorType::Interface;
    AsSubtype bDescriptorSubtype = AsSubtype::FormatType;
    FormatType bFormatType = FormatType::I;
    uint8_t bSubslotSize;    // bytes per sample slot (1..4)
    uint8_t bBitResolution;  // significant bits in the slot
};
static_assert(sizeof(FormatTypeIDescriptor) == 6);

// Table 4-33 Standard AS Isochronous Audio Data Endpoint Descriptor (7 bytes)
// Table 4-35 Standard AS Isochronous Feedback Endpoint Descriptor (7 bytes)
// Same layout; feedback uses bmAttributes = ISO | SYNC_NONE | USAGE_FEEDBACK.
struct StandardIsoEndpointDescriptor {
    uint8_t bLength = sizeof(StandardIsoEndpointDescriptor);
    StdDescriptorType bDescriptorType = StdDescriptorType::Endpoint;
    uint8_t bEndpointAddress;  // bit 7 = IN
    uint8_t bmAttributes;      // EpAttr bits
    uint16_t wMaxPacketSize;
    uint8_t bInterval;
};
static_assert(sizeof(StandardIsoEndpointDescriptor) == 7);

// Table 4-34 Class-Specific AS Isochronous Audio Data Endpoint Descriptor (8 bytes)
// (the feedback endpoint has no class-specific descriptor)
struct CsIsoEndpointDescriptor {
    uint8_t bLength = sizeof(CsIsoEndpointDescriptor);
    CsDescriptorType bDescriptorType = CsDescriptorType::Endpoint;
    EpSubtype bDescriptorSubtype = EpSubtype::General;
    uint8_t bmAttributes = 0;  // CsEpAttr
    uint8_t bmControls = 0;    // D1..0 pitch, D3..2 overrun, D5..4 underrun
    LockDelayUnits bLockDelayUnits = LockDelayUnits::Undefined;
    uint16_t wLockDelay = 0;
};
static_assert(sizeof(CsIsoEndpointDescriptor) == 8);

#pragma pack(pop)

}  // namespace uac2
