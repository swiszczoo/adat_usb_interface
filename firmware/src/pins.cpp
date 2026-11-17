#include "pins.hpp"

namespace Pins {

const Pin ULPI_D0 = { GPIOA, LL_GPIO_PIN_3 };
const Pin ULPI_D1 = { GPIOB, LL_GPIO_PIN_0 };
const Pin ULPI_D2 = { GPIOB, LL_GPIO_PIN_1 };
const Pin ULPI_D3 = { GPIOB, LL_GPIO_PIN_10 };
const Pin ULPI_D4 = { GPIOB, LL_GPIO_PIN_11 };
const Pin ULPI_D5 = { GPIOB, LL_GPIO_PIN_12 };
const Pin ULPI_D6 = { GPIOB, LL_GPIO_PIN_13 };
const Pin ULPI_D7 = { GPIOB, LL_GPIO_PIN_5 };
const Pin ULPI_NXT = { GPIOC, LL_GPIO_PIN_3 };
const Pin ULPI_DIR = { GPIOC, LL_GPIO_PIN_2 };
const Pin ULPI_STP = { GPIOC, LL_GPIO_PIN_0 };
const Pin ULPI_CLK = { GPIOA, LL_GPIO_PIN_5 };

}
