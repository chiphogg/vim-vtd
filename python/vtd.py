import libvtd.trusted_system


def UpdateTrustedSystem(file_name):
    """Make sure the TrustedSystem object is up to date."""
    global my_system
    my_system = libvtd.trusted_system.TrustedSystem()
    my_system.AddFile(file_name)
