#define _GNU_SOURCE 1 
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <unistd.h>
#include <signal.h>
#include <unistd.h>
#include <ucontext.h>
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
						bool reload_mode, uint32_t custom_coverage_bitmap_size,
						uint8_t pt_cr3_mode, uint64_t pt_cr3_mode_value){
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

	if(pt_cr3_mode){
		agent_config.pt_cr3_mode = pt_cr3_mode;
		agent_config.pt_cr3_mode_value = pt_cr3_mode_value;
	}

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

static void sig_segfault_handler(int signum, siginfo_t *info, void *extra){
	ucontext_t *context = (ucontext_t *)extra;

#if defined(__i386__)
	hprintf("Agent crashed at 0x%lx\n", context->uc_mcontext.gregs[REG_EIP]);
#else
	hprintf("Agent crashed at 0x%lx\n", context->uc_mcontext.gregs[REG_RIP]);
#endif

	if (context->uc_mcontext.gregs[REG_ERR] & 16) {
		hprintf(" * bad jump to 0x%lx\n", info->si_addr);
            
#if defined(__i386__)
		const unsigned long sp = context->uc_mcontext.gregs[REG_ESP];
#else
		const unsigned long sp = context->uc_mcontext.gregs[REG_RSP];
#endif
		if (sp && !(sp & 7)) {
			hprintf(" * by the instruction before => %lx\n", sp);
		}
	} 
	else{
        if (context->uc_mcontext.gregs[REG_ERR] & 2) {
			hprintf(" * invalid write attempt to %lx\n", info->si_addr);
		} 
		else {
			hprintf(" * invalid read attempt to %lx\n", info->si_addr);
		}
	}

    kAFL_hypercall(HYPERCALL_KAFL_PANIC, 0);
}

void install_segv_handler(void){
	struct sigaction action;
    action.sa_flags = SA_SIGINFO;
    action.sa_sigaction = sig_segfault_handler;
}

bool check_kpti(void){

	#define SYS_MELTDOWN_PATH "/sys/devices/system/cpu/vulnerabilities/meltdown"
	#define PTI_STR_LEN 15

	char* pti_str = "Mitigation: PTI";

	FILE *fp = fopen(SYS_MELTDOWN_PATH, "r");
	if (fp == NULL){
		return false;
	}
	fseek(fp, 0, SEEK_END);
	long size = ftell(fp);
	fclose(fp);

	if (size >= PTI_STR_LEN){
		char buf[PTI_STR_LEN];
		
		FILE *fp = fopen(SYS_MELTDOWN_PATH, "r");
		fread(buf, 1, PTI_STR_LEN, fp);
		fclose(fp);

		if (memcmp(buf, pti_str, PTI_STR_LEN) == 0){
			return true;
		}
	}

	return false;
}
