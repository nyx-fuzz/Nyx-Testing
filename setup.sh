
set -e

git submodule init
git submodule update

if [ ! -f "./packer/linux_initramfs/init.cpio.gz" ]; then
    cd packer/linux_initramfs/
    sh pack.sh
    cd -
fi

if [ ! -f "./qemu-nyx/x86_64-softmmu/qemu-system-x86_64" ]; then
    cd qemu-nyx
    ./compile_qemu_nyx.sh static
    cd -
fi