#include "configuration.hpp"

#include <stm32f4xx_ll_bus.h>
#include <stm32f4xx_ll_gpio.h>
#include <stm32f4xx_ll_utils.h>

#include <FreeRTOS.h>
#include <task.h>

void gownoEntry(void*)
{
    LL_AHB1_GRP1_EnableClock(LL_AHB1_GRP1_PERIPH_GPIOE);

    LL_GPIO_SetPinMode(GPIOE, LL_GPIO_PIN_0, LL_GPIO_MODE_OUTPUT);
    LL_GPIO_SetPinOutputType(GPIOE, LL_GPIO_PIN_0, LL_GPIO_OUTPUT_PUSHPULL);

    while (1) {
        LL_GPIO_TogglePin(GPIOE, LL_GPIO_PIN_0);

        for (volatile int i = 0; i < 500000; ++i) {}
    }
}

int main()
{
    SystemClock_Config();
    USB_Config();

    StaticTask_t gowno;
    StackType_t gownoStack[128];
    xTaskCreateStatic(gownoEntry, "gowno", 
        128, nullptr, 
        configMAX_PRIORITIES - 1, gownoStack, &gowno);

    xPortStartScheduler();

    return 0;
}
