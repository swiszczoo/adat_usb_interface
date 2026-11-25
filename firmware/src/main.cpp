#include "hardware.hpp"

#include "usb/task.hpp"

#include <FreeRTOS.h>
#include <task.h>

int main()
{
    HardwareInit();

    static UsbTask usbTask;
    usbTask.CreateTask(3, "Usb Task");

    vTaskStartScheduler();
    return 0;
}

// Interrupt handlers

extern "C" {

void HardFault_Handler()
{
    while (true) {}
}

}
