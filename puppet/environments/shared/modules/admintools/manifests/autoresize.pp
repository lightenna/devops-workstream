class admintools::autoresize (

  $device_name = 'sda',
  $partition_number = 1,

  $match_string = '0 part /',
  $size_unexpanded = undef, # e.g. 20G
  # by default, don't attempt to resize
  $size_expanded = undef, # e.g. 30G

) {

  # only attempt to manage partitions if sizes are explictly set
  if ($size_expanded != undef) and ($size_unexpanded != undef) {
    # linux-only
    case $operatingsystem {
      centos, redhat, oraclelinux, fedora, ubuntu, debian: {
        ensure_packages(['cloud-utils-growpart'], { ensure => 'present' })
        # execute command only-if the system reports that the partition is out of step with the disk (see match_string)
        exec { 'admintools-autoresize-apply' :
          path => ['/bin','/sbin','/usr/bin','/usr/sbin'],
          command => "growpart /dev/${device_name} ${partition_number} && partprobe && xfs_growfs /dev/${device_name}${partition_number}",
          onlyif => [
            # check that the disk is expanded
            "lsblk | grep '${device_name} ' | grep '0 disk' | grep '${size_expanded}'",
            # check that the partition is unexpanded
            "lsblk | grep '${device_name}${partition_number}' | grep '${match_string}' | grep '${size_unexpanded}'",
          ]
        }
      }
    }
  }

}