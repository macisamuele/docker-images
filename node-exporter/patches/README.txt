Those patches are needed to fix small node-exporter issues while running on docker-container

00-collector-netdev_linux-go.patch
    The patch changes the proc file used to extract network statistics.
    By default it uses /proc/net/dev which gets routed to a pseudo-file on /proc/<pid>/net/dev.
    The fact that <pid> is defined means that node-exporter will be able to get network statistics
    from a container point of view, so network usage in the container and not on the host.
    In order to address it should be enough to explicitly read from /proc/1/net/dev
