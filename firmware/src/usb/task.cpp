#include "task.hpp"

#include <tusb.h>

[[noreturn]] void UsbTask::TaskEntry()
{
    tusb_rhport_init_t dev_init = {
        .role = TUSB_ROLE_DEVICE,
        .speed = TUSB_SPEED_HIGH
    };
    tusb_init(BOARD_TUD_RHPORT, &dev_init);

    while (true) {
        tud_task();
    }
}

extern "C" void OTG_HS_IRQHandler()
{
    tud_int_handler(BOARD_TUD_RHPORT);
}
