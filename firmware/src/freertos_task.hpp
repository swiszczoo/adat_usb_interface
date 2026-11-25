#pragma once
#include <FreeRTOS.h>
#include <task.h>

#include <cstdlib>

template <typename T, std::size_t StackSize>
class FreeRTOSTask {
public:
    ~FreeRTOSTask() = default;
    FreeRTOSTask(const FreeRTOSTask&) = delete;
    FreeRTOSTask(FreeRTOSTask&&) = delete;
    FreeRTOSTask& operator=(const FreeRTOSTask&) = delete;
    FreeRTOSTask& operator=(FreeRTOSTask&&) = delete;

    TaskHandle_t CreateTask(int priority, const char* name)
    {
        return xTaskCreateStatic(FreeRTOSTask::FreeRTOSEntry, name,
            StackSize, this,
            priority, m_taskStack, &m_taskHandle);
    }

protected:
    FreeRTOSTask(T& task)
        : m_task(task)
    {
    }

private:
    T& m_task;
    StaticTask_t m_taskHandle {};
    StackType_t m_taskStack[StackSize] {};

    static void FreeRTOSEntry(void* params)
    {
        T* obj = reinterpret_cast<T*>(params);
        obj->TaskEntry();
    }
};
