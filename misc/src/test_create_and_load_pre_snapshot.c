#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <unistd.h>
#include "nyx.h"
#include "helper.h"

int main(int argc, char** argv){

	uint32_t bitmap_size, ijon_bitmap_size, payload_buffer_size;
	uint8_t* trace_buffer = allocate_page_aligend_buffer(DEFAULT_COVERAGE_BITMAP_SIZE);
	uint8_t* ijon_buffer = allocate_page_aligend_buffer(IJON_BUFFER_SIZE);

	dump_mappings();
	get_host_config(&bitmap_size, &ijon_bitmap_size, &payload_buffer_size);
	set_agent_config(true, (uintptr_t)trace_buffer, true, (uintptr_t)ijon_buffer, true, DEFAULT_COVERAGE_BITMAP_SIZE);

	kAFL_payload* payload_buffer = allocate_input_buffer(payload_buffer_size);
	kAFL_hypercall(HYPERCALL_KAFL_USER_FAST_ACQUIRE, 0);
	kAFL_hypercall(HYPERCALL_KAFL_RELEASE, 0);

	return 0;
}
