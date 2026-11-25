#pragma once
#include "usb_audio2.hpp"

#pragma pack(push, 1)

struct AudioInterfaceConfigurationDescriptor {
    uac2::ConfigurationDescriptor cd;
    uac2::InterfaceAssociationDescriptor iad;
    uac2::StandardInterfaceDescriptor acSid;
    struct {
        uac2::AcHeaderDescriptor ahd;
        uac2::ClockSourceDescriptor csd48;
        uac2::ClockSourceDescriptor csd44;
        uac2::ClockSelectorDescriptor<2> csd2;

        uac2::InputTerminalDescriptor out_itd;
        uac2::FeatureUnitDescriptor<16> out_fud16;
        uac2::OutputTerminalDescriptor out_otd;
        
        uac2::InputTerminalDescriptor in_itd;
        uac2::FeatureUnitDescriptor<16> in_fud16;
        uac2::OutputTerminalDescriptor in_otd;

    } ac;

    uac2::StandardInterfaceDescriptor out_asSid_alt0;
    uac2::StandardInterfaceDescriptor out_asSid_alt1;
    struct {
        uac2::AsGeneralDescriptor agd;
        uac2::FormatTypeIDescriptor ftd;
        uac2::StandardIsoEndpointDescriptor sied;
        uac2::CsIsoEndpointDescriptor cied;
    } out_as;

    uac2::StandardInterfaceDescriptor in_asSid_alt0;
    uac2::StandardInterfaceDescriptor in_asSid_alt1;
    struct {
        uac2::AsGeneralDescriptor agd;
        uac2::FormatTypeIDescriptor ftd;
        uac2::StandardIsoEndpointDescriptor sied;
        uac2::CsIsoEndpointDescriptor cied;
    } in_as;
};

#pragma pack(pop)
