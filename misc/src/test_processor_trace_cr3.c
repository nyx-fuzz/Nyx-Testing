#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "nyx.h"
#include "helper.h"

int main(int argc, char** argv){

	uint32_t bitmap_size, ijon_bitmap_size, payload_buffer_size;
	uint8_t* ijon_buffer = allocate_page_aligend_buffer(IJON_BUFFER_SIZE);

	dump_mappings();
	get_host_config(&bitmap_size, &ijon_bitmap_size, &payload_buffer_size);
	set_agent_config(false, (uintptr_t)NULL, true, (uintptr_t)ijon_buffer, true, DEFAULT_COVERAGE_BITMAP_SIZE, 0, 0);

	kAFL_payload* payload_buffer = allocate_input_buffer(payload_buffer_size);

	uint64_t* ranges = malloc(sizeof(uint64_t)*3);
    memset(ranges, 0x0, sizeof(uint64_t)*3);

	ranges[0] = (uint64_t)0x1000;
	ranges[1] = (uint64_t)0xffffffffffffffff;
    ranges[2] = 0;

    kAFL_hypercall(HYPERCALL_KAFL_RANGE_SUBMIT, (uintptr_t)ranges);


#ifdef TEST_NO_CR3_FILTER
	kAFL_hypercall(HYPERCALL_KAFL_NEXT_PAYLOAD, 0);
	kAFL_hypercall(HYPERCALL_KAFL_ACQUIRE, 0);
#else
	kAFL_hypercall(HYPERCALL_KAFL_USER_FAST_ACQUIRE, 0);
#endif
	write(open("/tmp/fooo", O_CREAT | O_WRONLY, 0444), "ABCD", 4);

	kAFL_hypercall(HYPERCALL_KAFL_RELEASE, 0);

	return 0;
}
