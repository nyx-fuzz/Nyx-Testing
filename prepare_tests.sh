set -e

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

#echo "Compiling test: test_invalid_config_64"
#cp -R out/sharedir_template_64 out/test_invalid_config_64/
#gcc misc/src/helper.c  misc/src/test_invalid_config.c -static -I misc/src/ -I ./packer/ -o out/test_invalid_config_64/target
#gcc misc/src/helper.c  misc/src/test_invalid_config.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_invalid_config_64/target_no_pt

#echo "Compiling test: test_invalid_config_32"
#cp -R out/sharedir_template_32 out/test_invalid_config_32/
#gcc misc/src/helper.c  misc/src/test_invalid_config.c -static -I misc/src/ -I ./packer/ -o out/test_invalid_config_32/target
#gcc misc/src/helper.c  misc/src/test_invalid_config.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_invalid_config_32/target_no_pt

echo "Compiling test: test_hget_fail_64"
cp -R out/sharedir_template_64 out/test_hget_fail_64/

echo "Compiling test: test_hget_fail_32"
cp -R out/sharedir_template_32 out/test_hget_fail_32/

echo "Compiling test: test_input_buffer_write_protection_64"
cp -R out/sharedir_template_64 out/test_input_buffer_write_protection_64/
gcc misc/src/helper.c  misc/src/test_input_buffer_write_protection.c -static -I misc/src/ -I ./packer/ -o out/test_input_buffer_write_protection_64/target
gcc misc/src/helper.c  misc/src/test_input_buffer_write_protection.c -static -I misc/src/ -I ./packer/  -DNO_PT_NYX -o out/test_input_buffer_write_protection_64/target_no_pt

echo "Compiling test: test_input_buffer_write_protection_64"
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
