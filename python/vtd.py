import libvtd.trusted_system


def UpdateTrustedSystem(file_name):
    """Make sure the TrustedSystem object is up to date."""
    global my_system
    if 'my_system' not in globals():
        my_system = libvtd.trusted_system.TrustedSystem()
        my_system.AddFile(file_name)
    my_system.Refresh()
