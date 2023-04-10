extern crate nix;

#[cfg(test)]
mod tests {
    use std::process::Command;
    use nix::unistd::gettid;
    use std::fs;
    //use std::sync::Once;
    use std::path::Path;
    use libnyx::*;

    //static INIT: Once = Once::new();

    pub fn setup() -> () { 
        /*
        INIT.call_once(|| {
            let mut root = env::current_dir().unwrap();
            root.push("tests");
            assert!(env::set_current_dir(&root).is_ok());

            let output = Command::new("sh")
                .arg("build.sh")
                .output()
                .expect("failed to execute process");

            println!("Build script: {}", String::from_utf8_lossy(&output.stdout));
            
            root.pop();
            assert!(env::set_current_dir(&root).is_ok());
        });
        */
    }

    fn init_qemu(target: &str, workdir: &str, input_buffer_size: u32, create_snapshot: bool, is_parent: bool, input_buffer_write_protection: bool) -> Result<NyxProcess, String>{

        let process = match (create_snapshot, is_parent){
            (false, false) => NyxProcess::new(target, workdir, 0, input_buffer_size, input_buffer_write_protection),
            (true, true) => NyxProcess::new_parent(target, workdir, 0, input_buffer_size, input_buffer_write_protection),
            (true, false) => NyxProcess::new_child(target, workdir, 0, 1),
            _ => panic!("invalid"),
        };

        let qemu = match process{
            Ok(mut x) => {
                x.option_set_reload_mode(true);
                x.option_apply();
                x
            },
            Err(msg) => {
                return Err(msg);
                //panic!("{}", msg);
            }
        };

        Ok(qemu)
    }

    fn init(target: &str, workdir: &str, input_buffer_size: u32, input_buffer_write_protection: bool) -> Result<NyxProcess, String>{
        init_qemu(target, workdir, input_buffer_size, false, false, input_buffer_write_protection)
    }

    fn init_parent(target: &str, workdir: &str, input_buffer_size: u32, input_buffer_write_protection: bool) -> Result<NyxProcess, String>{
        init_qemu(target, workdir, input_buffer_size, true, true, input_buffer_write_protection)
    }

    fn init_child(target: &str, workdir: &str, input_buffer_size: u32) -> Result<NyxProcess, String>{
        init_qemu(target, workdir, input_buffer_size, true, false, false)
    }

    fn init_default(target: &str, workdir: &str, input_buffer_write_protection: bool) -> Result<NyxProcess, String>{
        init(target, workdir, 0x20000, input_buffer_write_protection)
    }

    fn init_parent_default(target: &str, workdir: &str, input_buffer_write_protection: bool) -> Result<NyxProcess, String>{
        init_qemu(target, workdir, 0x20000, true, true, input_buffer_write_protection)
    }

    fn init_child_default(target: &str, workdir: &str) -> Result<NyxProcess, String>{
        init_qemu(target, workdir, 0x20000, true, false, false)
    }

    fn test_early_abort(sharedir: &str, error_msg: &str){
        setup();
        let workdir = &format!("/tmp/workdir_{}", gettid());

        let process = init_default(sharedir, workdir, false);
        
        let success = match process{
            Err(x) => {
                println!("--> {}", x);
                if x.contains(error_msg) {
                    //"VM_EXIT_KAFL_GET_HOST_CONFIG was not called") || x.contains("VM_EXIT_KAFL_SET_AGENT_CONFIG was not called") {
                    true
                }
                else{
                    false
                }
            },
            Ok(mut x) => {
                x.shutdown();
                false
            },
        };

        match fs::remove_dir_all(Path::new(workdir)){
            Ok(_) => {},
            Err(_) => {},
        };

        assert!(success);
    }

    fn test_processor_trace(sharedir: &str, use_redqueen: bool){
        setup();
        let workdir = &format!("/tmp/workdir_{}", gettid());

        let mut process = init_default(sharedir, workdir, false).unwrap();
        
        let mut success;

        let size = 10;
        let input_data = "KEAAELAFL\x00".as_bytes();
        process.set_input(input_data, size);
        process.exec();

        let input_buffer = process.bitmap_buffer();      
        success = !input_buffer.iter().all(|x| *x == 0x00);

        if use_redqueen {
            process.option_set_redqueen_mode(true);
            process.option_apply();
            process.exec();
        }

        success = if use_redqueen {
            let trace_size = fs::metadata(format!("{}/redqueen_workdir_0/redqueen_results.txt", workdir)).unwrap().len();
            println!("Trace Size: {}", trace_size);
            trace_size != 0
        }
        else {
            success
        };
        
        process.shutdown();
        fs::remove_dir_all(Path::new(workdir)).unwrap();

        assert!(success);
    }

    fn test_coverage_bitmap(sharedir: &str){
        setup();
        let workdir = &format!("/tmp/workdir_{}", gettid());
        let mut process = init_default(sharedir, workdir, false).unwrap();
        
        let mut success = true;

        process.exec();
        let input_buffer = process.input_buffer();      
        let bitmap_buffer = process.bitmap_buffer();     
        
        if success{
            success = bitmap_buffer.iter().all(|x| *x == 0xAA);
        }
        if success{
            success = input_buffer.iter().all(|x| *x == 0xCC);
        }

        process.shutdown();
        fs::remove_dir_all(Path::new(workdir)).unwrap();

        assert!(success);
    }

    fn test_resize_coverage_bitmap(sharedir: &str) {
        setup();
        
        const INPUT_BUFFFER_SIZE: u32 = 0x100000;  /* test if we can pass up to 1MB */
        let workdir = &format!("/tmp/workdir_{}", gettid());
        let mut process = init(sharedir, workdir, INPUT_BUFFFER_SIZE, false).unwrap();

        process.exec();
        let input_buffer = process.input_buffer();    
        let mut success = input_buffer.len() == INPUT_BUFFFER_SIZE as usize;

        if success {
            success = input_buffer.iter().all(|x| *x == 0xCC);
        }

        process.shutdown();
        fs::remove_dir_all(Path::new(workdir)).unwrap();

        assert!(success);
    }


    fn test_resize_coverage_bitmap_host_to_guest(sharedir: &str) {
        setup();
        
        const INPUT_BUFFFER_SIZE: u32 = 0x1000;
        let workdir = &format!("/tmp/workdir_{}", gettid());
        let mut process = init(sharedir, workdir, INPUT_BUFFFER_SIZE, false).unwrap();

        let input_buffer = process.input_buffer_mut();      
        let mut success = input_buffer.len() == INPUT_BUFFFER_SIZE as usize;

        if success {
            input_buffer.iter_mut().for_each(|v| *v = 0xDD as u8);
            //input_buffer.iter_mut().skip(0xab).take(1).for_each(|v| *v = 0 as u8);

            let ret = process.exec();
            success =  match ret {
                NyxReturnValue::Normal => true,
                _ => false,
            };
        }

        process.shutdown();
        fs::remove_dir_all(Path::new(workdir)).unwrap();

        assert!(success);
    }

    fn test_resize_coverage_bitmap_host_to_guest_fail(sharedir: &str) {
        setup();
        
        const INPUT_BUFFFER_SIZE: u32 = 0x1000;
        let workdir = &format!("/tmp/workdir_{}", gettid());
        let mut process = init(sharedir, workdir, INPUT_BUFFFER_SIZE, false).unwrap();

        let input_buffer = process.input_buffer_mut();      
        let mut success = input_buffer.len() == INPUT_BUFFFER_SIZE as usize;

        if success {
            input_buffer.iter_mut().for_each(|v| *v = 0xDD as u8);
            input_buffer.iter_mut().skip(0xab).take(1).for_each(|v| *v = 0 as u8);

            let ret = process.exec();
            success =  match ret {
                NyxReturnValue::Abort => true,
                _ => false,
            };
        }

        process.shutdown();
        fs::remove_dir_all(Path::new(workdir)).unwrap();

        assert!(success);
    }

    #[test]
    fn test_create_and_load_pre_snapshot() {
        setup();
        /* create pre snapshot */
        let config = NyxConfig::load("out/test_custom_buffer_sizes_host_to_guest_64/").unwrap();
        //println!("config: {}", config);

        let qemu_binary = config.qemu_binary_path().unwrap();
        let kernel_image = config.kernel_image_path().unwrap();
        let ramfs_image = config.ramfs_image_path().unwrap();

        let mut cmd = vec![];
        cmd.push(qemu_binary.to_string());
        cmd.push("-kernel".to_string());
        cmd.push(kernel_image.to_string());
        cmd.push("-initrd".to_string());
        cmd.push(ramfs_image.to_string());
        cmd.push("-append".to_string());
        cmd.push("nokaslr oops=panic nopti ignore_rlimit_data".to_string());
        cmd.push("-display".to_string());
        cmd.push("none".to_string());
        cmd.push("-enable-kvm".to_string());

        cmd.push("-net".to_string());
        cmd.push("none".to_string());

        cmd.push("-hda".to_string());
        cmd.push("/tmp/hda".to_string());

        cmd.push("-k".to_string());
        cmd.push("de".to_string());
        cmd.push("-m".to_string());
        cmd.push("512".to_string());

        cmd.push("-machine".to_string());
        cmd.push("kAFL64-v1".to_string());

        cmd.push("-cpu".to_string());
        cmd.push("kAFL64-Hypervisor-v1,+vmx".to_string());

        cmd.push("-d".to_string());
        cmd.push("nyx".to_string());
        cmd.push("-D".to_string());
        cmd.push("/tmp/qemu_nyx_log".to_string());

        cmd.push("-fast_vm_reload".to_string());
        cmd.push("pre_path=/tmp/snapshot_new,load=off".to_string());

        //println!("{}", &cmd.join(" "));

        if Path::new(&format!("/tmp/snapshot_new")).exists(){
            fs::remove_dir_all("/tmp/snapshot_new").unwrap();
        }
        fs::create_dir("/tmp/snapshot_new").unwrap();
        
        Command::new(&cmd[0])
        .args(&cmd[1..])
        .env("NYX_DISABLE_DIRTY_RING", "y")
        .output()
        .expect("failed to execute process");

        let output = fs::read_to_string("/tmp/qemu_nyx_log").unwrap();
        assert!(output.contains("Creating pre image snapshot"));
        assert!(output.contains("switching to secondary CoW buffer"));

        /* load pre snapshot */        
        let workdir = &format!("/tmp/workdir_{}", gettid());
        let mut process = init_default("out/test_create_and_load_pre_snapshot/", workdir, false).unwrap();

        let success =  match process.exec() {
            NyxReturnValue::Normal => true,
            _ => false,
        };

        process.shutdown();
        fs::remove_dir_all(Path::new(workdir)).unwrap();

        if Path::new(&format!("/tmp/snapshot_new")).exists(){
            fs::remove_dir_all("/tmp/snapshot_new").unwrap();
        }
        
        assert!(success);
    }

    fn test_load_root_snapshot(sharedir: &str) {
        setup();

        let workdir = &format!("/tmp/workdir_{}", gettid());
        let mut process = init_parent_default(sharedir, workdir, false).unwrap();

        process.shutdown();
        let mut process = init_child_default(sharedir, workdir).unwrap();

        let success =  match process.exec() {
            NyxReturnValue::Normal => true,
            _ => false,
        };

        process.shutdown();
        fs::remove_dir_all(Path::new(workdir)).unwrap();

        assert!(success);
    }

    fn test_load_root_snapshot_with_custom_input_size(sharedir: &str) {
        setup();
        const INPUT_BUFFFER_SIZE: u32 = 0x100000;

        let workdir = &format!("/tmp/workdir_{}", gettid());
        let mut process = init_parent(sharedir, workdir, INPUT_BUFFFER_SIZE, false).unwrap();

        process.shutdown();
        let mut process = init_child(sharedir, workdir, INPUT_BUFFFER_SIZE).unwrap();

        let mut success =  match process.exec() {
            NyxReturnValue::Normal => true,
            _ => false,
        };

        let input_buffer = process.input_buffer();      
        let bitmap_buffer = process.bitmap_buffer();     
        
        if success{
            success = input_buffer.len() == INPUT_BUFFFER_SIZE as usize;
            println!("size: {} {}", input_buffer.len(), INPUT_BUFFFER_SIZE);
        }

        if success{
            success = bitmap_buffer.iter().all(|x| *x == 0xAA);
            if !success {
                println!("bitmap buffer check failed");
            }
        }
        if success{
            success = input_buffer.iter().all(|x| *x == 0xCC);
            if !success {
                println!("input buffer check failed");
            }
        }

        process.shutdown();    
        fs::remove_dir_all(Path::new(workdir)).unwrap();

        assert!(success);
    }

    fn test_hget_fail(sharedir: &str) {
        setup();

        let workdir = &format!("/tmp/workdir_{}", gettid());
        let process = init_parent_default(sharedir, workdir, false);

        let success = match process{
            Ok(mut x) => {
                x.shutdown();
                false
            },
            Err(x) => {
                if x.contains("Error: Hypervisor has rejected stream buffer (file not found)") {
                    true
                }
                else{
                    false
                }
            },
        };
        
        fs::remove_dir_all(Path::new(workdir)).unwrap();

        assert!(success);
    }

    fn test_input_buffer_write_protection(sharedir: &str) {
        setup();
        
        let workdir = &format!("/tmp/workdir_{}", gettid());
        let mut process = init_default(sharedir, workdir, true).unwrap();

        let mut success = match process.exec(){
            NyxReturnValue::InvalidWriteToPayload => true,
            x => {
                println!("{:?}", x);
                false
            },
        };

        process.shutdown();

        if success {
            let mut process = init_default(sharedir, workdir, false).unwrap();

            success = match process.exec(){
                NyxReturnValue::Normal => true,
                x => {
                    println!("{:?}", x);
                    false
                },
            };
    
            process.shutdown();
        }

        fs::remove_dir_all(Path::new(workdir)).unwrap();

        assert!(success);
    }

    fn test_input_buffer_write_protection_child(sharedir: &str) {
        setup();
        
        let workdir = &format!("/tmp/workdir_{}", gettid());
        let mut process = init_parent_default(sharedir, workdir, true).unwrap();

        process.shutdown();
        let mut process = init_child_default(sharedir, workdir).unwrap();

        let mut success = match process.exec(){
            NyxReturnValue::InvalidWriteToPayload => true,
            x => {
                println!("{:?}", x);
                false
            },
        };

        process.shutdown();

        if success {
            let mut process = init_parent_default(sharedir, workdir, false).unwrap();

            process.shutdown();
            let mut process = init_child_default(sharedir, workdir).unwrap();

            success = match process.exec(){
                NyxReturnValue::Normal => true,
                x => {
                    println!("{:?}", x);
                    false
                },
            };

            process.shutdown();
        }
        fs::remove_dir_all(Path::new(workdir)).unwrap();

        assert!(success);
    }


    fn test_call_illegal_hypercalls(sharedir: &str) {
        setup();
        
        let workdir = &format!("/tmp/workdir_{}", gettid());
        let mut process = init_default(sharedir, workdir, true).unwrap();

        let success = match process.exec(){
            NyxReturnValue::Abort => true,
            x => {
                println!("{:?}", x);
                false
            },
        };

        process.shutdown();
        fs::remove_dir_all(Path::new(workdir)).unwrap();

        assert!(success);
    }

    fn test_call_illegal_hypercalls_child(sharedir: &str) {
        setup();
        
        let workdir = &format!("/tmp/workdir_{}", gettid());
        let mut process = init_parent_default(sharedir, workdir, true).unwrap();

        process.shutdown();
        let mut process = init_child_default(sharedir, workdir).unwrap();

        let success = match process.exec(){
            NyxReturnValue::Abort => true,
            x => {
                println!("{:?}", x);
                false
            },
        };

        process.shutdown();
        fs::remove_dir_all(Path::new(workdir)).unwrap();

        assert!(success);
    }

    #[test]
    fn coverage_bitmap_64() {
        test_coverage_bitmap("out/test_custom_buffer_sizes_64/");
    }

    #[test]
    fn coverage_bitmap_32() {
        test_coverage_bitmap("out/test_custom_buffer_sizes_32/");
    }

    #[test]
    fn resize_coverage_bitmap_64() {
        test_resize_coverage_bitmap("out/test_custom_buffer_sizes_64/");
    }

    #[test]
    fn resize_coverage_bitmap_32() {
        test_resize_coverage_bitmap("out/test_custom_buffer_sizes_32/");
    }

    #[test]
    fn resize_small_coverage_bitmap_64() {
        test_resize_coverage_bitmap("out/test_resize_small_coverage_bitmap_64/");
    }

    #[test]
    fn resize_small_coverage_bitmap_32() {
        test_resize_coverage_bitmap("out/test_resize_small_coverage_bitmap_32/");
    }

    #[test]
    fn resize_coverage_bitmap_host_to_guest_64() {
        test_resize_coverage_bitmap_host_to_guest("out/test_custom_buffer_sizes_host_to_guest_64/");
    }

    #[test]
    fn resize_coverage_bitmap_host_to_guest_32() {
        test_resize_coverage_bitmap_host_to_guest("out/test_custom_buffer_sizes_host_to_guest_32/");
    }

    #[test]
    fn resize_coverage_bitmap_host_to_guest_fail_64() {
        test_resize_coverage_bitmap_host_to_guest_fail("out/test_custom_buffer_sizes_host_to_guest_64/");
    }

    #[test]
    fn resize_coverage_bitmap_host_to_guest_fail_32() {
        test_resize_coverage_bitmap_host_to_guest_fail("out/test_custom_buffer_sizes_host_to_guest_32/");
    }

    #[test]
    fn hget_fail_64() {
        test_hget_fail("out/test_hget_fail_64/");
    }

    #[test]
    fn hget_fail_32() {
        test_hget_fail("out/test_hget_fail_32/");
    }

    #[test]
    fn input_buffer_write_protection_32() {
        test_input_buffer_write_protection("out/test_input_buffer_write_protection_64/");
    }

    #[test]
    fn input_buffer_write_protection_64() {
        test_input_buffer_write_protection("out/test_input_buffer_write_protection_64/");
    }

    #[test]
    fn input_buffer_write_protection_child_32() {
        test_input_buffer_write_protection_child("out/test_input_buffer_write_protection_64/");
    }

    #[test]
    fn input_buffer_write_protection_child_64() {
        test_input_buffer_write_protection_child("out/test_input_buffer_write_protection_64/");
    }

    #[test]
    fn load_root_snapshot_64() {
        test_load_root_snapshot("out/test_custom_buffer_sizes_64/");
    }

    #[test]
    fn load_root_snapshot_32() {
        test_load_root_snapshot("out/test_custom_buffer_sizes_32/");
    }

    #[test]
    fn load_root_snapshot_with_custom_input_size_64() {
        test_load_root_snapshot_with_custom_input_size("out/test_custom_buffer_sizes_64/");
    }

    #[test]
    fn load_root_snapshot_with_custom_input_size_32() {
        test_load_root_snapshot_with_custom_input_size("out/test_custom_buffer_sizes_32/");
    }

    #[test]
    fn call_illegal_hypercalls(){
        test_call_illegal_hypercalls("out/test_call_invalid_hypercalls/")
    }

    #[test]
    fn call_illegal_hypercalls_child(){
        test_call_illegal_hypercalls_child("out/test_call_invalid_hypercalls/")
    }

    #[test]
    fn skip_get_host_configuration_64(){
        test_early_abort("out/test_skip_get_host_configuration_64/", "KVM_EXIT_KAFL_GET_HOST_CONFIG was not called")
    }

    #[test]
    fn skip_get_host_configuration_32(){
        test_early_abort("out/test_skip_get_host_configuration_32/", "KVM_EXIT_KAFL_GET_HOST_CONFIG was not called")
    }

    #[test]
    fn skip_set_agent_configuration_64(){
        test_early_abort("out/test_skip_set_agent_configuration_64/", "KVM_EXIT_KAFL_SET_AGENT_CONFIG was not called")
    }

    #[test]
    fn skip_set_agent_configuration_32(){
        test_early_abort("out/test_skip_set_agent_configuration_32/", "KVM_EXIT_KAFL_SET_AGENT_CONFIG was not called")
    }


    #[test]
    fn set_agent_configuration_twice_64(){
        test_early_abort("out/test_set_agent_configuration_twice_32/", "KVM_EXIT_KAFL_SET_AGENT_CONFIG called twice...")
    }

    #[test]
    fn set_agent_configuration_twice_32(){
        test_early_abort("out/test_set_agent_configuration_twice_32/", "KVM_EXIT_KAFL_SET_AGENT_CONFIG called twice...")
    }

    #[test]
    fn processor_trace_64(){
        test_processor_trace("out/test_processor_trace_64/", false)
    }

    #[test]
    fn processor_trace_32(){
        test_processor_trace("out/test_processor_trace_32/", false)
    }

    #[test]
    fn processor_trace_redqueen_64(){
        test_processor_trace("out/test_processor_trace_64/", true)
    }

    #[test]
    fn processor_trace_redqueen_32(){
        test_processor_trace("out/test_processor_trace_32/", true)
    }
}

