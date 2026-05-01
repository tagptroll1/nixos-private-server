{ config, pkgs, ... }: {
  # GTX 1070 (Pascal) passed through from Proxmox via VFIO.
  # Proprietary driver because nouveau power management on Pascal
  # is unreliable for sustained ML/encode workloads.

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
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    nvidia-vaapi-driver
  ];
}
