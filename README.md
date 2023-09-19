# Nyx Test Framework

A simple unit test framework for the QEMU-Nyx hypervisor backend.

<p>
<img align="right" width="200"  src="logo.png">
</p>

## Dependency
required package
```
sudo apt install -y libgtk-3-dev libc6-dev-i386 gcc-multilib
```
check KVM
```
sudo modprobe -r kvm-intel
sudo modprobe -r kvm
sudo modprobe  kvm enable_vmware_backdoor=y
sudo modprobe  kvm-intel
cat /sys/module/kvm/parameters/enable_vmware_backdoor
```
## Build

```
sh setup.sh
sh prepare_tests.sh
```

## Run

```
./run_tests.sh

# to start additional Intel Processor Trace tests run the following command
./run_tests_pt.sh
```

## Bug Reports and Contributions

If you found or fixed a bug on your own: We are very open to patches. Please create a pull request!  

### License

This tool is provided under **AGPL license**. 

**Free Software Hell Yeah!** 

Proudly provided by: 
* [Sergej Schumilo](http://schumilo.de) - sergej@schumilo.de / [@ms_s3c](https://twitter.com/ms_s3c)
