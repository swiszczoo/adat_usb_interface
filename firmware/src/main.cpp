#include "configuration.hpp"
#include "tusb_config.h"

#include <stm32f4xx_ll_bus.h>
#include <stm32f4xx_hal_cortex.h>
#include <stm32f4xx_ll_gpio.h>
#include <stm32f4xx_ll_utils.h>

#include <FreeRTOS.h>
#include <task.h>
#include <tusb.h>

void vApplicationStackOverflowHook(TaskHandle_t pxTask, char* pcTaskName)
{
    assert(false);
}

void gownoEntry(void*)
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

extern "C" void HardFault_Handler()
{
    while (true) {}
}

extern "C" void OTG_HS_IRQHandler()
{
    tud_int_handler(BOARD_TUD_RHPORT);
}

int main()
{
    NVIC_SetPriorityGrouping(NVIC_PRIORITYGROUP_4);
    SystemClock_Config();
    USB_Config();

    static StaticTask_t gowno;
    static StackType_t gownoStack[1024];
    xTaskCreateStatic(gownoEntry, "gowno",
        1024, nullptr,
        configMAX_PRIORITIES - 1, gownoStack, &gowno);

    vTaskStartScheduler();
    return 0;
}
