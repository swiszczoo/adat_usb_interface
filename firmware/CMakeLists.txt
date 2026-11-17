cmake_minimum_required(VERSION 3.20)
project(adat_usb_interface)

# Configure the project
project(adat_usb_interface C CXX ASM)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_C_STANDARD 17)
set(CMAKE_CXX_STANDARD 20)

# Configure FreeRTOS-Kernel
add_library(freertos_config INTERFACE)
target_include_directories(freertos_config SYSTEM INTERFACE config) # The config file directory
target_compile_definitions(freertos_config INTERFACE projCOVERAGE_TEST=0)
set(FREERTOS_PORT "GCC_ARM_CM4F")

# Add dependencies
add_subdirectory(lib)

set(STARTUP_ASM "startup_stm32f429xx.s")

file(GLOB_RECURSE SOURCES "src/*")

add_executable(${PROJECT_NAME}.elf ${SOURCES} ${STARTUP_ASM} ${LINKER_SCRIPT})
target_include_directories(${PROJECT_NAME}.elf PRIVATE "${PROJECT_BINARY_DIR}")
target_link_libraries(${PROJECT_NAME}.elf PRIVATE 
  freertos_kernel stm32f4xx-hal-driver tinyusb)
target_compile_definitions(stm32f4xx-hal-driver PUBLIC -DSTM32F429xx)

target_include_directories(tinyusb PUBLIC config)
target_link_libraries(tinyusb PRIVATE freertos_kernel)
target_link_libraries(tinyusb PRIVATE stm32f4xx-hal-driver)

# Add system config file
target_sources(${PROJECT_NAME}.elf PRIVATE 
    lib/cmsis-device-f4/Source/Templates/system_stm32f4xx.c)

# Set linker script
set(LINKER_SCRIPT ${CMAKE_CURRENT_LIST_DIR}/STM32F429XX_FLASH.ld)
target_link_options(${PROJECT_NAME}.elf PRIVATE "-T${LINKER_SCRIPT}")

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_definitions(-D_DEBUG)
endif (CMAKE_BUILD_TYPE STREQUAL "Debug")

set(HEX_FILE ${PROJECT_BINARY_DIR}/${PROJECT_NAME}.hex)
set(BIN_FILE ${PROJECT_BINARY_DIR}/${PROJECT_NAME}.bin)

add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -Oihex $<TARGET_FILE:${PROJECT_NAME}.elf> ${HEX_FILE}
        COMMAND ${CMAKE_OBJCOPY} -Obinary $<TARGET_FILE:${PROJECT_NAME}.elf> ${BIN_FILE}
        COMMENT "Building ${HEX_FILE}
Building ${BIN_FILE}")

# Custom targets for interfacing with openocd

if (CMAKE_HOST_WIN32)
    add_custom_target(flash
            COMMAND openocd -f openocd.cfg -c init -c targets -c "reset init" -c "\"flash write_image erase \\\"${HEX_FILE}\\\"\"" -c "reset run" -c shutdown
            DEPENDS ${PROJECT_NAME}.elf
            COMMENT "Building and flashing ${PROJECT_NAME}.elf using openocd"
            SOURCES openocd.cfg
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )
else ()
    add_custom_target(flash
            COMMAND openocd -f openocd.cfg -c init -c targets -c "reset init" -c "flash write_image erase ${HEX_FILE}" -c "reset run" -c shutdown
            DEPENDS ${PROJECT_NAME}.elf
            COMMENT "Building and flashing ${PROJECT_NAME}.elf using openocd"
            SOURCES openocd.cfg
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )
endif ()
