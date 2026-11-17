file(GLOB_RECURSE SOURCES 
    "tinyusb/src/*.c"
)

add_library(tinyusb STATIC ${SOURCES})
target_compile_definitions(tinyusb PUBLIC -DCFG_TUSB_MCU=OPT_MCU_STM32F4)
target_include_directories(tinyusb PRIVATE tinyusb/src)
target_include_directories(tinyusb INTERFACE tinyusb/src)
