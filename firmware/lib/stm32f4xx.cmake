project(stm32f4xx-hal-driver)

file(GLOB_RECURSE LL_SOURCES 
    "stm32f4xx-hal-driver/Src/stm32f4xx_ll_utils.c")

add_library(${PROJECT_NAME} STATIC ${LL_SOURCES})
target_include_directories(${PROJECT_NAME} PUBLIC stm32f4xx-hal-driver/Inc)
target_include_directories(${PROJECT_NAME} PUBLIC cmsis-core/CMSIS/Core/Include)
target_include_directories(${PROJECT_NAME} PUBLIC cmsis-device-f4/Include)
