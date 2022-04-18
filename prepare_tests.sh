set -e

dd if=/dev/zero of=/tmp/hda count=1024 bs=1024

rm -rf out/

mkdir -p out/
mkdir -p out/sharedir_template_64
mkdir -p out/sharedir_template_32

cd packer/packer/linux_x86_64-userspace/
sh compile_32.sh
sh compile_64.sh
cd -

cp packer/packer/linux_x86_64-userspace/bin64/h* out/sharedir_template_64/
cp packer/packer/linux_x86_64-userspace/bin32/h* out/sharedir_template_32/

cp misc/config.ron out/sharedir_template_64/
cp misc/fuzz_no_pt.sh out/sharedir_template_64/
cp misc/fuzz.sh out/sharedir_template_64/

cp misc/config.ron out/sharedir_template_32/
cp misc/fuzz_no_pt.sh out/sharedir_template_32/
cp misc/fuzz.sh out/sharedir_template_32/

echo "Compiling test: test_custom_buffer_sizes_64"
cp -R out/sharedir_template_64 out/test_custom_buffer_sizes_64/
gcc misc/src/helper.c  misc/src/test_custom_buffer_sizes.c -static -I misc/src/ -I ./packer/ -o out/test_custom_buffer_sizes_64/target
gcc misc/src/helper.c  misc/src/test_custom_buffer_sizes.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_custom_buffer_sizes_64/target_no_pt

echo "Compiling test: test_custom_buffer_sizes_32"
cp -R out/sharedir_template_32 out/test_custom_buffer_sizes_32/
gcc misc/src/helper.c  misc/src/test_custom_buffer_sizes.c -m32 -static -I misc/src/ -I ./packer/ -o out/test_custom_buffer_sizes_32/target
gcc misc/src/helper.c  misc/src/test_custom_buffer_sizes.c -m32 -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_custom_buffer_sizes_32/target_no_pt

echo "Compiling test: test_custom_buffer_sizes_host_to_guest_64"
cp -R out/sharedir_template_64 out/test_custom_buffer_sizes_host_to_guest_64/
gcc misc/src/helper.c  misc/src/test_custom_buffer_sizes_host_to_guest.c -static -I misc/src/ -I ./packer/ -o out/test_custom_buffer_sizes_host_to_guest_64/target
gcc misc/src/helper.c  misc/src/test_custom_buffer_sizes_host_to_guest.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_custom_buffer_sizes_host_to_guest_64/target_no_pt

echo "Compiling test: test_custom_buffer_sizes_host_to_guest_32"
cp -R out/sharedir_template_32 out/test_custom_buffer_sizes_host_to_guest_32/
gcc misc/src/helper.c  misc/src/test_custom_buffer_sizes_host_to_guest.c -m32 -static -I misc/src/ -I ./packer/ -o out/test_custom_buffer_sizes_host_to_guest_32/target
gcc misc/src/helper.c  misc/src/test_custom_buffer_sizes_host_to_guest.c -m32 -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_custom_buffer_sizes_host_to_guest_32/target_no_pt

echo "Compiling test: test_resize_small_coverage_bitmap_64"
cp -R out/sharedir_template_64 out/test_resize_small_coverage_bitmap_64/
gcc misc/src/helper.c  misc/src/test_resize_small_coverage_bitmap.c -static -I misc/src/ -I ./packer/ -o out/test_resize_small_coverage_bitmap_64/target
gcc misc/src/helper.c  misc/src/test_resize_small_coverage_bitmap.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_resize_small_coverage_bitmap_64/target_no_pt

echo "Compiling test: test_resize_small_coverage_bitmap_32"
cp -R out/sharedir_template_32 out/test_resize_small_coverage_bitmap_32/
gcc misc/src/helper.c  misc/src/test_resize_small_coverage_bitmap.c -static -I misc/src/ -I ./packer/ -o out/test_resize_small_coverage_bitmap_32/target
gcc misc/src/helper.c  misc/src/test_resize_small_coverage_bitmap.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_resize_small_coverage_bitmap_32/target_no_pt

echo "Compiling test: test_hget_fail_64"
cp -R out/sharedir_template_64 out/test_hget_fail_64/

echo "Compiling test: test_hget_fail_32"
cp -R out/sharedir_template_32 out/test_hget_fail_32/

echo "Compiling test: test_input_buffer_write_protection_64"
cp -R out/sharedir_template_64 out/test_input_buffer_write_protection_64/
gcc misc/src/helper.c  misc/src/test_input_buffer_write_protection.c -static -I misc/src/ -I ./packer/ -o out/test_input_buffer_write_protection_64/target
gcc misc/src/helper.c  misc/src/test_input_buffer_write_protection.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_input_buffer_write_protection_64/target_no_pt

echo "Compiling test: test_input_buffer_write_protection_32"
cp -R out/sharedir_template_32 out/test_input_buffer_write_protection_32/
gcc misc/src/helper.c  misc/src/test_input_buffer_write_protection.c -m32 -static -I misc/src/ -I ./packer/ -o out/test_input_buffer_write_protection_32/target
gcc misc/src/helper.c  misc/src/test_input_buffer_write_protection.c -m32 -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_input_buffer_write_protection_32/target_no_pt

echo "Compiling test: test_call_invalid_hypercalls"
cp -R out/sharedir_template_64 out/test_call_invalid_hypercalls/
gcc misc/src/helper.c  misc/src/test_call_invalid_hypercalls.c -static -I misc/src/ -I ./packer/ -o out/test_call_invalid_hypercalls/target
gcc misc/src/helper.c  misc/src/test_call_invalid_hypercalls.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_call_invalid_hypercalls/target_no_pt

echo "Compiling test: test_create_and_load_pre_snapshot"
cp -R out/sharedir_template_64 out/test_create_and_load_pre_snapshot/
gcc misc/src/helper.c  misc/src/test_create_and_load_pre_snapshot.c -static -I misc/src/ -I ./packer/ -o out/test_create_and_load_pre_snapshot/target
gcc misc/src/helper.c  misc/src/test_create_and_load_pre_snapshot.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_create_and_load_pre_snapshot/target_no_pt
cp misc/config_snapshot.ron out/test_create_and_load_pre_snapshot/config.ron

echo "Compiling test: test_skip_get_host_configuration_64"
cp -R out/sharedir_template_64 out/test_skip_get_host_configuration_64/
gcc misc/src/helper.c  misc/src/test_skip_get_host_configuration.c -static -I misc/src/ -I ./packer/ -o out/test_skip_get_host_configuration_64/target
gcc misc/src/helper.c  misc/src/test_skip_get_host_configuration.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_skip_get_host_configuration_64/target_no_pt

echo "Compiling test: test_skip_get_configuration_32"
cp -R out/sharedir_template_32 out/test_skip_get_host_configuration_32/
gcc misc/src/helper.c  misc/src/test_skip_get_host_configuration.c -m32 -static -I misc/src/ -I ./packer/ -o out/test_skip_get_host_configuration_32/target
gcc misc/src/helper.c  misc/src/test_skip_get_host_configuration.c -m32 -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_skip_get_host_configuration_32/target_no_pt

echo "Compiling test: test_skip_set_agent_configuration_64"
cp -R out/sharedir_template_64 out/test_skip_set_agent_configuration_64/
gcc misc/src/helper.c  misc/src/test_skip_set_agent_configuration.c -static -I misc/src/ -I ./packer/ -o out/test_skip_set_agent_configuration_64/target
gcc misc/src/helper.c  misc/src/test_skip_set_agent_configuration.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_skip_set_agent_configuration_64/target_no_pt

echo "Compiling test: test_skip_set_agent_configuration_64"
cp -R out/sharedir_template_32 out/test_skip_set_agent_configuration_32/
gcc misc/src/helper.c  misc/src/test_skip_set_agent_configuration.c -m32 -static -I misc/src/ -I ./packer/ -o out/test_skip_set_agent_configuration_32/target
gcc misc/src/helper.c  misc/src/test_skip_set_agent_configuration.c -m32 -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_skip_set_agent_configuration_32/target_no_pt

echo "Compiling test: test_get_host_configuration_twice_64"
cp -R out/sharedir_template_64 out/test_get_host_configuration_twice_64/
gcc misc/src/helper.c  misc/src/test_get_host_configuration_twice.c -static -I misc/src/ -I ./packer/ -o out/test_get_host_configuration_twice_64/target
gcc misc/src/helper.c  misc/src/test_get_host_configuration_twice.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_get_host_configuration_twice_64/target_no_pt

echo "Compiling test: test_get_host_configuration_twice_32"
cp -R out/sharedir_template_32 out/test_get_host_configuration_twice_32/
gcc misc/src/helper.c  misc/src/test_get_host_configuration_twice.c -m32 -static -I misc/src/ -I ./packer/ -o out/test_get_host_configuration_twice_32/target
gcc misc/src/helper.c  misc/src/test_get_host_configuration_twice.c -m32 -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_get_host_configuration_twice_32/target_no_pt

echo "Compiling test: test_set_agent_configuration_twice_64"
cp -R out/sharedir_template_64 out/test_set_agent_configuration_twice_64/
gcc misc/src/helper.c  misc/src/test_set_agent_configuration_twice.c -static -I misc/src/ -I ./packer/ -o out/test_set_agent_configuration_twice_64/target
gcc misc/src/helper.c  misc/src/test_set_agent_configuration_twice.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_set_agent_configuration_twice_64/target_no_pt

echo "Compiling test: test_set_agent_configuration_twice_32"
cp -R out/sharedir_template_32 out/test_set_agent_configuration_twice_32/
gcc misc/src/helper.c  misc/src/test_set_agent_configuration_twice.c -m32 -static -I misc/src/ -I ./packer/ -o out/test_set_agent_configuration_twice_32/target
gcc misc/src/helper.c  misc/src/test_set_agent_configuration_twice.c -m32 -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_set_agent_configuration_twice_32/target_no_pt

echo "Compiling test: test_processor_trace_64"
cp -R out/sharedir_template_64 out/test_processor_trace_64/
gcc misc/src/helper.c  misc/src/test_processor_trace.c -m64 -static -I misc/src/ -I ./packer/ -o out/test_processor_trace_64/target
gcc misc/src/helper.c  misc/src/test_processor_trace.c -m64 -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_processor_trace_64/target_no_pt

echo "Compiling test: test_processor_trace_32"
cp -R out/sharedir_template_32 out/test_processor_trace_32/
gcc misc/src/helper.c  misc/src/test_processor_trace.c -m32 -static -I misc/src/ -I ./packer/ -o out/test_processor_trace_32/target
gcc misc/src/helper.c  misc/src/test_processor_trace.c -m32 -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_processor_trace_32/target_no_pt

echo "Compiling test: test_processor_trace_kernel_64"
cp -R out/sharedir_template_64 out/test_processor_trace_kernel_64/
gcc misc/src/helper.c  misc/src/test_processor_trace.c -m64 -DTEST_PT_KERNEL -static -I misc/src/ -I ./packer/ -o out/test_processor_trace_kernel_64/target
gcc misc/src/helper.c  misc/src/test_processor_trace.c -m64 -DTEST_PT_KERNEL -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_processor_trace_kernel_64/target_no_pt

echo "Compiling test: test_processor_trace_kernel_32"
cp -R out/sharedir_template_32 out/test_processor_trace_kernel_32/
gcc misc/src/helper.c  misc/src/test_processor_trace.c -m32 -DTEST_PT_KERNEL -static -I misc/src/ -I ./packer/ -o out/test_processor_trace_kernel_32/target
gcc misc/src/helper.c  misc/src/test_processor_trace.c -m32 -DTEST_PT_KERNEL -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_processor_trace_kernel_32/target_no_pt

echo "Compiling test: test_processor_trace_invalid_range_64"
cp -R out/sharedir_template_64 out/test_processor_trace_invalid_range_64/
gcc misc/src/helper.c  misc/src/test_processor_trace_invalid_ip_config.c -m64 -DTEST_INVALID_RANGE -static -I misc/src/ -I ./packer/ -o out/test_processor_trace_invalid_range_64/target
gcc misc/src/helper.c  misc/src/test_processor_trace_invalid_ip_config.c -m64 -DTEST_INVALID_RANGE -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_processor_trace_invalid_range_64/target_no_pt

echo "Compiling test: test_processor_trace_invalid_range_32"
cp -R out/sharedir_template_32 out/test_processor_trace_invalid_range_32/
gcc misc/src/helper.c  misc/src/test_processor_trace_invalid_ip_config.c -m32 -DTEST_INVALID_RANGE -static -I misc/src/ -I ./packer/ -o out/test_processor_trace_invalid_range_32/target
gcc misc/src/helper.c  misc/src/test_processor_trace_invalid_ip_config.c -m32 -DTEST_INVALID_RANGE -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_processor_trace_invalid_range_32/target_no_pt

echo "Compiling test: test_processor_trace_no_range_64"
cp -R out/sharedir_template_64 out/test_processor_trace_no_range_64/
gcc misc/src/helper.c  misc/src/test_processor_trace_invalid_ip_config.c -m64 -static -I misc/src/ -I ./packer/ -o out/test_processor_trace_no_range_64/target
gcc misc/src/helper.c  misc/src/test_processor_trace_invalid_ip_config.c -m64 -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_processor_trace_no_range_64/target_no_pt

echo "Compiling test: test_processor_trace_no_range_32"
cp -R out/sharedir_template_32 out/test_processor_trace_no_range_32/
gcc misc/src/helper.c  misc/src/test_processor_trace_invalid_ip_config.c -m32 -static -I misc/src/ -I ./packer/ -o out/test_processor_trace_no_range_32/target
gcc misc/src/helper.c  misc/src/test_processor_trace_invalid_ip_config.c -m32 -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_processor_trace_no_range_32/target_no_pt

echo "Compiling test: test_processor_trace_no_cr3_filter_64"
cp -R out/sharedir_template_64 out/test_processor_trace_no_cr3_filter_64/
gcc misc/src/helper.c  misc/src/test_processor_trace_cr3.c -m64 -DTEST_NO_CR3_FILTER -static -I misc/src/ -I ./packer/ -o out/test_processor_trace_no_cr3_filter_64/target
gcc misc/src/helper.c  misc/src/test_processor_trace_cr3.c -m64 -DTEST_NO_CR3_FILTER -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_processor_trace_no_cr3_filter_64/target_no_pt

echo "Compiling test: test_processor_trace_no_cr3_filter_32"
cp -R out/sharedir_template_32 out/test_processor_trace_no_cr3_filter_32/
gcc misc/src/helper.c  misc/src/test_processor_trace_cr3.c -m32 -DTEST_NO_CR3_FILTER -static -I misc/src/ -I ./packer/ -o out/test_processor_trace_no_cr3_filter_32/target
gcc misc/src/helper.c  misc/src/test_processor_trace_cr3.c -m32 -DTEST_NO_CR3_FILTER -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_processor_trace_no_cr3_filter_32/target_no_pt

echo "Compiling test: test_memory_access_64"
cp -R out/sharedir_template_64 out/test_memory_access_64/
gcc misc/src/helper.c  misc/src/test_memory_access.c -m64 -static -I misc/src/ -I ./packer/ -o out/test_memory_access_64/target
gcc misc/src/helper.c  misc/src/test_memory_access.c -m64 -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_memory_access_64/target_no_pt

echo "Compiling test: test_memory_access_32"
cp -R out/sharedir_template_64 out/test_memory_access_32/
gcc misc/src/helper.c  misc/src/test_memory_access.c -m32 -static -I misc/src/ -I ./packer/ -o out/test_memory_access_32/target
gcc misc/src/helper.c  misc/src/test_memory_access.c -m32 -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_memory_access_32/target_no_pt

echo "Compiling test: test_memory_access_snapshot_64"
cp -R out/sharedir_template_64 out/test_memory_access_snapshot_64/
gcc misc/src/helper.c  misc/src/test_memory_access.c -m64 -DTEST_SNAPSHOT_MEMORY -static -I misc/src/ -I ./packer/ -o out/test_memory_access_snapshot_64/target
gcc misc/src/helper.c  misc/src/test_memory_access.c -m64 -DTEST_SNAPSHOT_MEMORY -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_memory_access_snapshot_64/target_no_pt

echo "Compiling test: test_memory_access_snapshot_32"
cp -R out/sharedir_template_64 out/test_memory_access_snapshot_32/
gcc misc/src/helper.c  misc/src/test_memory_access.c -m32 -DTEST_SNAPSHOT_MEMORY -static -I misc/src/ -I ./packer/ -o out/test_memory_access_snapshot_32/target
gcc misc/src/helper.c  misc/src/test_memory_access.c -m32 -DTEST_SNAPSHOT_MEMORY -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_memory_access_snapshot_32/target_no_pt
