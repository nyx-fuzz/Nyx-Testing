#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <unistd.h>
#include "nyx.h"
#include "helper.h"

#define DEFAULT_COVERAGE_BITMAP_SIZE (1024*64)
#define IJON_BUFFER_SIZE 4096

void hassert(bool expression, char* msg){
	if (!expression){
		habort(msg);
	}
}

void dump_mappings(void){
    char filename[256];

    char* buffer = malloc(0x1000);

    kafl_dump_file_t file_obj = {0};


    file_obj.file_name_str_ptr = (uintptr_t)"proc_maps.txt";
    file_obj.append = 0;
    file_obj.bytes = 0;
    kAFL_hypercall(HYPERCALL_KAFL_DUMP_FILE, (uintptr_t) (&file_obj));
    file_obj.append = 1;


  	snprintf(filename, 256, "/proc/%d/maps", getpid());

	if(access(filename, R_OK) != 0){
		return;
	}

  	FILE* f = fopen(filename, "r");
    uint32_t len = 0;
    while(1){
  	    len = fread(buffer, 1, 0x1000, f);
        if(!len){
            break;
        }
        else{

            file_obj.bytes = len;
            file_obj.data_ptr = (uintptr_t)buffer;
            kAFL_hypercall(HYPERCALL_KAFL_DUMP_FILE, (uintptr_t) (&file_obj));
        }
    }
    fclose(f);
}

void get_host_config(uint32_t* bitmap_size, uint32_t* ijon_bitmap_size, uint32_t* payload_buffer_size){
	host_config_t host_config;
    kAFL_hypercall(HYPERCALL_KAFL_GET_HOST_CONFIG, (uintptr_t)&host_config);

	hassert((host_config.host_magic == NYX_HOST_MAGIC && host_config.host_version == NYX_HOST_VERSION), "NYX_HOST_MAGIC/NYX_HOST_VERSION mismatch");

	hprintf("[capablities] host_config.bitmap_size: 0x%"PRIx64"\n", host_config.bitmap_size);
    hprintf("[capablities] host_config.ijon_bitmap_size: 0x%"PRIx64"\n", host_config.ijon_bitmap_size);
    hprintf("[capablities] host_config.payload_buffer_size: 0x%"PRIx64"x\n", host_config.payload_buffer_size);

	*bitmap_size = host_config.bitmap_size;
	*ijon_bitmap_size = host_config.bitmap_size;
	*payload_buffer_size = host_config.payload_buffer_size;
}

void set_agent_config(bool enable_agent_trace_buffer, uintptr_t trace_buffer_vaddr, 
						bool enable_ijon_trace_buffer, uintptr_t ijon_trace_buffer_vaddr, 
						bool reload_mode, uint32_t custom_coverage_bitmap_size){
	agent_config_t agent_config = {0};
    agent_config.agent_magic = NYX_AGENT_MAGIC;
    agent_config.agent_version = NYX_AGENT_VERSION;

	agent_config.agent_timeout_detection = 0;
	agent_config.agent_tracing = enable_agent_trace_buffer;
	agent_config.agent_ijon_tracing = enable_ijon_trace_buffer;
	agent_config.trace_buffer_vaddr = (uintptr_t)trace_buffer_vaddr;
	agent_config.ijon_trace_buffer_vaddr = (uintptr_t)ijon_trace_buffer_vaddr;
    agent_config.agent_non_reload_mode = 1;
    agent_config.coverage_bitmap_size = custom_coverage_bitmap_size;

    kAFL_hypercall(HYPERCALL_KAFL_SET_AGENT_CONFIG, (uintptr_t)&agent_config);
}

uint8_t* allocate_page_aligend_buffer(size_t size){
	uint8_t* buffer = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
	hassert(buffer != NULL && buffer != (void*)-1, "allocate_page_aligend_buffer failed");

	mlock(buffer, size);
	memset(buffer, 0, size);
	return buffer;
}

kAFL_payload* allocate_input_buffer(uint32_t payload_buffer_size){
	kAFL_payload* payload_buffer = (kAFL_payload*)allocate_page_aligend_buffer(payload_buffer_size);
	kAFL_hypercall(HYPERCALL_KAFL_GET_PAYLOAD, (uintptr_t)payload_buffer);
	hprintf("[init] payload buffer is mapped at %p (size: 0x%lx)\n", payload_buffer, payload_buffer_size);
	return payload_buffer;
}
