#pragma once

#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <unistd.h>
#include "nyx.h"

#define DEFAULT_COVERAGE_BITMAP_SIZE (1024*64)
#define IJON_BUFFER_SIZE 4096

void hassert(bool expression, char* msg);
void dump_mappings(void);
void get_host_config(uint32_t* bitmap_size, uint32_t* ijon_bitmap_size, uint32_t* payload_buffer_size);
void set_agent_config(bool enable_agent_trace_buffer, uintptr_t trace_buffer_vaddr, 
						bool enable_ijon_trace_buffer, uintptr_t ijon_trace_buffer_vaddr, 
						bool reload_mode, uint32_t custom_coverage_bitmap_size,
						uint8_t pt_cr3_mode, uint64_t pt_cr3_mode_value);
uint8_t* allocate_page_aligend_buffer(size_t size);
kAFL_payload* allocate_input_buffer(uint32_t payload_buffer_size);
void install_segv_handler(void);
bool check_kpti(void);
