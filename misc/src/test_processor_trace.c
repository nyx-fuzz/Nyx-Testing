#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <unistd.h>
#include "nyx.h"
#include "helper.h"

void test_func(char* input, size_t size){

	hprintf("Input: %s (size: %d)\n", input, size);

	if (size >= 9){

		if(!strcmp(input, "TEST")){
    		kAFL_hypercall(HYPERCALL_KAFL_PANIC, 0);
		}

		if(input[0] == 'K')
			if(input[1] == 'E')
				if(input[2] == 'R')
					if(input[3] == 'N')
						if(input[4] == 'E')
							if(input[5] == 'L')
								if(input[6] == 'A')
									if(input[7] == 'F')
										if(input[8] == 'L')
    										kAFL_hypercall(HYPERCALL_KAFL_PANIC, 0);
	}


}

int main(int argc, char** argv){

	uint32_t bitmap_size, ijon_bitmap_size, payload_buffer_size;
	uint8_t* ijon_buffer = allocate_page_aligend_buffer(IJON_BUFFER_SIZE);

	dump_mappings();
	get_host_config(&bitmap_size, &ijon_bitmap_size, &payload_buffer_size);
	set_agent_config(false, (uintptr_t)NULL, true, (uintptr_t)ijon_buffer, true, DEFAULT_COVERAGE_BITMAP_SIZE);

	kAFL_payload* payload_buffer = allocate_input_buffer(payload_buffer_size);

	uint64_t* ranges = malloc(sizeof(uint64_t)*3);
    memset(ranges, 0x0, sizeof(uint64_t)*3);
	ranges[0] = (uintptr_t)0x1000;
	ranges[1] = (uintptr_t)0x7ffffffff000;
    ranges[2] = 0;

	install_segv_handler();

    kAFL_hypercall(HYPERCALL_KAFL_RANGE_SUBMIT, (uintptr_t)ranges);

	kAFL_hypercall(HYPERCALL_KAFL_USER_FAST_ACQUIRE, 0);

	test_func(payload_buffer->data, payload_buffer->size);

	kAFL_hypercall(HYPERCALL_KAFL_RELEASE, 0);

	return 0;
}
