#pragma once
#include "../freertos_task.hpp"

#include <FreeRTOS.h>
#include <task.h>

class UsbTask : public FreeRTOSTask<UsbTask, 512> {
public:
    UsbTask()
        : FreeRTOSTask(*this)
    {
    }

    [[noreturn]] void TaskEntry();

};
