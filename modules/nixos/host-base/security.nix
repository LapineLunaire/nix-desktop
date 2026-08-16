{...}: {
  # "!" locks the root account.
  users.users.root.hashedPassword = "!";
  users.mutableUsers = false;

  security.protectKernelImage = true;
  # KPTI mitigates Meltdown-class attacks by isolating kernel page tables from user space.
  security.forcePageTableIsolation = true;

  boot.kernelParams = [
    # Keeps slab caches unmerged, which hardens against heap exploits.
    "slab_nomerge"
    # Randomises the page allocator freelist order.
    "page_alloc.shuffle=1"
  ];

  boot.kernel.sysctl = {
    # 2 hides kernel pointers even from processes holding CAP_SYSLOG.
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    # Mitigates SYN flood attacks.
    "net.ipv4.tcp_syncookies" = 1;
    # Strict reverse path filtering: a packet arriving on an interface that would not route back through it is dropped, and logged as a martian.
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    # Ignores broadcast ICMP, which mitigates SMURF.
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    # Incoming ICMP redirects are ignored. The conf.default keys carry each setting to interfaces that appear after the sysctls are applied.
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    # Sending ICMP redirects is disabled. The knob exists for IPv4 only.
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
  };

  security.apparmor.enable = true;
  security.apparmor.enableCache = true;
  security.apparmor.killUnconfinedConfinables = true;

  security.sudo.enable = false;

  nix.settings.allowed-users = ["@users"];
}
