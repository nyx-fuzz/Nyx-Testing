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

	uint8_t* trace_buffer = allocate_page_aligend_buffer(DEFAULT_COVERAGE_BITMAP_SIZE);
	uint32_t bitmap_size, ijon_bitmap_size, payload_buffer_size;
	uint8_t* ijon_buffer = allocate_page_aligend_buffer(IJON_BUFFER_SIZE);

	dump_mappings();
	get_host_config(&bitmap_size, &ijon_bitmap_size, &payload_buffer_size);
	set_agent_config(true, (uintptr_t)trace_buffer, true, (uintptr_t)ijon_buffer, true, DEFAULT_COVERAGE_BITMAP_SIZE, 0, 0);

	kAFL_payload* payload_buffer = allocate_input_buffer(payload_buffer_size);

	nyx_debug_t debug_reg;

	uint8_t* test_buffer_8 =   (uint8_t*)  allocate_page_aligend_buffer(0x2000);
	uint16_t* test_buffer_16 = (uint16_t*) allocate_page_aligend_buffer(0x2000);
	uint32_t* test_buffer_32 = (uint32_t*) allocate_page_aligend_buffer(0x2000);
	uint64_t* test_buffer_64 = (uint64_t*) allocate_page_aligend_buffer(0x2000);

	for (int i = 0; i < 0x2000; i++){
		test_buffer_8[i] = i;
	}

	for (int i = 0; i < 0x2000/2; i++){
		test_buffer_16[i] = i;
	}

	for (int i = 0; i < 0x2000/4; i++){
		test_buffer_32[i] = i;
	}

#if !defined(__i386__)
	for (int i = 0; i < 0x2000/8; i++){
		test_buffer_64[i] = i;
	}
#endif

	install_segv_handler();

	/* create snapshot */
	kAFL_hypercall(HYPERCALL_KAFL_USER_FAST_ACQUIRE, 0);

#ifdef TEST_SNAPSHOT_MEMORY
	uint64_t mode = 7;
	memset(test_buffer_8, 0, 0x2000);
	memset(test_buffer_16, 0, 0x2000);
	memset(test_buffer_32, 0, 0x2000);
	memset(test_buffer_64, 0, 0x2000);

#else
	uint64_t mode = 6;
#endif
	for (int i = 0; i < 0x2000; i++){
		debug_reg.arg0 = mode;
		debug_reg.arg1 = (uintptr_t)&test_buffer_8[i];
		debug_reg.arg2 = (uint64_t)i;
		debug_reg.arg3 = (uint64_t)0; /* 8 bit */
		kAFL_hypercall(HYPERCALL_KAFL_DEBUG, (uintptr_t)&debug_reg);
	}

	for (int i = 0; i < 0x2000/2; i++){
		debug_reg.arg0 = mode;
		debug_reg.arg1 = (uintptr_t)&test_buffer_16[i];
		debug_reg.arg2 = (uint64_t)i;
		debug_reg.arg3 = (uint64_t)1; /* 16 bit */
		kAFL_hypercall(HYPERCALL_KAFL_DEBUG, (uintptr_t)&debug_reg);
	}

	for (int i = 0; i < 0x2000/4; i++){
		debug_reg.arg0 = mode;
		debug_reg.arg1 = (uintptr_t)&test_buffer_32[i];
		debug_reg.arg2 = (uint64_t)i;
		debug_reg.arg3 = (uint64_t)2; /* 32 bit */
		kAFL_hypercall(HYPERCALL_KAFL_DEBUG, (uintptr_t)&debug_reg);
	}

#if !defined(__i386__)
	for (int i = 0; i < 0x2000/8; i++){
		debug_reg.arg0 = mode;
		debug_reg.arg1 = (uintptr_t)&test_buffer_64[i];
		debug_reg.arg2 = (uint64_t)i;
		debug_reg.arg3 = (uint64_t)3; /* 64 bit */
		kAFL_hypercall(HYPERCALL_KAFL_DEBUG, (uintptr_t)&debug_reg);
	}
#endif
	kAFL_hypercall(HYPERCALL_KAFL_RELEASE, 0);

	return 0;
}
