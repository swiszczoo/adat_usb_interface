# Specify the cross compiler
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR cortex-m4)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
set(AS arm-none-eabi-as)
set(AR arm-none-eabi-ar)
set(CMAKE_OBJCOPY arm-none-eabi-objcopy)
set(CMAKE_OBJDUMP arm-none-eabi-objdump)
set(CMAKE_SIZE arm-none-eabi-size)

set(COMMON_FLAGS "-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16 -ffunction-sections -fno-exceptions -fdata-sections --specs=nosys.specs --specs=nano.specs -lnosys")

set(CMAKE_C_FLAGS "${COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS "${COMMON_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-Wl,-gc-sections -Wl,--print-memory-usage")

add_definitions(
    -D__weak=__attribute__\(\(weak\)\) 
    -D__packed=__attribute__\(\(__packed__\)\) 
    -DARM_MATH_CM4
)
