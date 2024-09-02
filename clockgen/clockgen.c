#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/clocks.h"
#include "hardware/structs/clocks.h"

#define PWM_PIN 16
#define PWM_SLICE 0

void print_rate(uint32_t div, uint8_t frac) {
	printf("PWM set to %f MHz (%ld:%d).\n", 125.0 / (div + (frac / 256.0)), div, frac);
}

void print_prompt() {
	printf("\n> ");
}

void rate_add(uint32_t* div, uint8_t* frac, int8_t delta) {
	uint32_t tmp = (*div << 8) | *frac;
	tmp += delta;
	*div = (tmp >> 8) & 0xFFFFFF;
	*frac = tmp & 0xFF;
}

void rate_update(uint32_t div, uint8_t frac) {
	clock_gpio_init_int_frac(
		21,
		CLOCKS_CLK_GPOUT0_CTRL_AUXSRC_VALUE_CLKSRC_PLL_SYS,
		div,
		frac
	);
}

int main() {
	uint32_t div = 4;
	uint8_t frac = 247;

	stdio_init_all();

	gpio_init(PICO_DEFAULT_LED_PIN);
	gpio_set_dir(PICO_DEFAULT_LED_PIN, GPIO_OUT);

	sleep_ms(2000);

	print_rate(div, frac);
	print_prompt();

	rate_update(div, frac);

	while (true) {
		char c = getchar();
		gpio_put(PICO_DEFAULT_LED_PIN, 1);
		switch (c) {
		case '\r':
			print_rate(div, frac);
			break;
		case '-':
			rate_add(&div, &frac, 1);
			rate_update(div, frac);
			print_rate(div, frac);
			break;
		case '+':
			rate_add(&div, &frac, -1);
			rate_update(div, frac);
			print_rate(div, frac);
			break;
		}
		gpio_put(PICO_DEFAULT_LED_PIN, 0);
		print_prompt();
	}
}
