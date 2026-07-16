#include "FreeRTOS.h"
#include "task.h"

#define LED (*(volatile unsigned int *) 0x03000000)

#ifndef SLOW_DELAY
#define SLOW_DELAY pdMS_TO_TICKS(250)
#endif
#ifndef FAST_DELAY
#define FAST_DELAY pdMS_TO_TICKS(60)
#endif

static void blink_slow(void *pv) {
  (void) pv;
  for (;;) {
    LED ^= 0x0001;
    vTaskDelay(SLOW_DELAY);
  }
}

static void blink_fast(void *pv) {
  (void) pv;
  for (;;) {
    LED ^= 0x8000;
    vTaskDelay(FAST_DELAY);
  }
}

int main(void) {
  LED = 0x0200;  // entered main
  xTaskCreate(blink_slow, "slow", configMINIMAL_STACK_SIZE, NULL, 1, NULL);
  xTaskCreate(blink_fast, "fast", configMINIMAL_STACK_SIZE, NULL, 1, NULL);
  LED = 0x0300;  // tasks created
  vTaskStartScheduler();
  for (;;) {
  }
}

void vApplicationMallocFailedHook(void) {
  for (;;) {
  }
}
