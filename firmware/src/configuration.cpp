#include "pins.hpp"

#include <stm32f4xx_ll_bus.h>
#include <stm32f4xx_ll_pwr.h>
#include <stm32f4xx_ll_rcc.h>
#include <stm32f4xx_ll_system.h>
#include <stm32f4xx_ll_utils.h>

#include <array>

void SystemClock_Config()
{
    LL_APB2_GRP1_EnableClock(LL_APB2_GRP1_PERIPH_SYSCFG);
    LL_APB1_GRP1_EnableClock(LL_APB1_GRP1_PERIPH_PWR);

    LL_FLASH_SetLatency(LL_FLASH_LATENCY_5);
    while (LL_FLASH_GetLatency() != LL_FLASH_LATENCY_5) {
    }

    LL_PWR_SetRegulVoltageScaling(LL_PWR_REGU_VOLTAGE_SCALE1);
    LL_PWR_EnableOverDriveMode();
    LL_RCC_HSE_Enable();

    /* Wait till HSE is ready */
    while (LL_RCC_HSE_IsReady() != 1) {
    }
    LL_RCC_PLL_ConfigDomain_SYS(LL_RCC_PLLSOURCE_HSE, LL_RCC_PLLM_DIV_12,
        180, LL_RCC_PLLP_DIV_2);
    LL_RCC_PLL_Enable();

    /* Wait till PLL is ready */
    while (LL_RCC_PLL_IsReady() != 1) {
    }
    while (LL_PWR_IsActiveFlag_VOS() == 0) {
    }
    LL_RCC_SetAHBPrescaler(LL_RCC_SYSCLK_DIV_1);
    LL_RCC_SetAPB1Prescaler(LL_RCC_APB1_DIV_4);
    LL_RCC_SetAPB2Prescaler(LL_RCC_APB2_DIV_2);
    LL_RCC_SetSysClkSource(LL_RCC_SYS_CLKSOURCE_PLL);

    /* Wait till System clock is ready */
    while (LL_RCC_GetSysClkSource() != LL_RCC_SYS_CLKSOURCE_STATUS_PLL) {
    }
    LL_SetSystemCoreClock(180000000);

    LL_RCC_ConfigMCO(LL_RCC_MCO1SOURCE_HSE, LL_RCC_MCO1_DIV_1);
    LL_RCC_SetTIMPrescaler(LL_RCC_TIM_PRESCALER_TWICE);
}

void USB_Config()
{
    static const std::array<const Pin, 12> USB_PINS = {
        Pins::ULPI_D0,
        Pins::ULPI_D1,
        Pins::ULPI_D2,
        Pins::ULPI_D3,
        Pins::ULPI_D4,
        Pins::ULPI_D5,
        Pins::ULPI_D6,
        Pins::ULPI_D7,
        Pins::ULPI_NXT,
        Pins::ULPI_DIR,
        Pins::ULPI_STP,
        Pins::ULPI_CLK,
    };

    LL_AHB1_GRP1_EnableClock(LL_AHB1_GRP1_PERIPH_GPIOA
        | LL_AHB1_GRP1_PERIPH_GPIOB
        | LL_AHB1_GRP1_PERIPH_GPIOC
        | LL_AHB1_GRP1_PERIPH_OTGHS
        | LL_AHB1_GRP1_PERIPH_OTGHSULPI);

    for (const auto& pin : USB_PINS) {
        LL_GPIO_SetPinMode(pin.port, pin.pin, LL_GPIO_MODE_ALTERNATE);

        if (pin.pin < LL_GPIO_PIN_8) {
            LL_GPIO_SetAFPin_0_7(pin.port, pin.pin, LL_GPIO_AF_10);
        } else {
            LL_GPIO_SetAFPin_8_15(pin.port, pin.pin, LL_GPIO_AF_10);
        }

        LL_GPIO_SetPinOutputType(pin.port, pin.pin, LL_GPIO_OUTPUT_PUSHPULL);
        LL_GPIO_SetPinSpeed(pin.port, pin.pin, LL_GPIO_SPEED_FREQ_VERY_HIGH);
        LL_GPIO_SetPinPull(pin.port, pin.pin, LL_GPIO_PULL_NO);
    }

    NVIC_EnableIRQ(OTG_HS_IRQn);
    NVIC_SetPriority(OTG_HS_IRQn, 5);

    LL_GPIO_SetPinMode(Pins::USB_RESET.port, Pins::USB_RESET.pin, LL_GPIO_MODE_OUTPUT);
    LL_GPIO_SetPinOutputType(Pins::USB_RESET.port, 
        Pins::USB_RESET.pin, LL_GPIO_OUTPUT_PUSHPULL);
    LL_GPIO_ResetOutputPin(Pins::USB_RESET.port, Pins::USB_RESET.pin);
}
