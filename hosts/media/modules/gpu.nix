{ config, pkgs, ... }: {
  # GTX 1070 (Pascal) passed through from Proxmox via VFIO.
  # Proprietary driver because nouveau power management on Pascal
  # is unreliable for sustained ML/encode workloads.

  # Block in-tree drivers so the device is free for nvidia to claim at boot.
  boot.blacklistedKernelModules = [ "nouveau" "nvidiafb" ];

  # Force-load the nvidia kernel modules early so headless boot picks
  # the GPU up without depending on xserver activation.
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  # Also wires the userspace driver derivation in (libGL, ICDs, etc.).
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = false;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = false;
    powerManagement.enable = false;
    # GTX 1070 (Pascal) is unsupported by the 595.xx mainline driver.
    # Pin to the 580.xx Legacy branch — last branch that binds to GP104.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
  ];
}
