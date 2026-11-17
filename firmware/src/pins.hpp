#pragma once
#include <cstdint>
#include <stm32f4xx_ll_gpio.h>

struct Pin {
    GPIO_TypeDef* port;
    uint16_t pin;
};

namespace Pins {

extern const Pin ULPI_D0;
extern const Pin ULPI_D1;
extern const Pin ULPI_D2;
extern const Pin ULPI_D3;
extern const Pin ULPI_D4;
extern const Pin ULPI_D5;
extern const Pin ULPI_D6;
extern const Pin ULPI_D7;
extern const Pin ULPI_NXT;
extern const Pin ULPI_DIR;
extern const Pin ULPI_STP;
extern const Pin ULPI_CLK;
extern const Pin USB_RESET;

}
