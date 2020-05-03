# lesson2

## Создаем Vagrantfile

Создаем `vagrantfile` по средствам которого создается машина с именем `Noda`
двух ядерным процессором и 1024 ОЗУ и тремя дополнительными дисками:

```
# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :Noda => {
        :box_name => "centos/7",
        :ip_addr => '192.168.11.101',
    :disks => {
        :sata1 => {
            :dfile => './sata1.vdi',
            :size => 250,
            :port => 1
        },
        :sata2 => {
                        :dfile => './sata2.vdi',
                        :size => 250, # Megabytes
            :port => 2
        },
                :sata3 => {
                        :dfile => './sata3.vdi',
                        :size => 250,
                        :port => 3
                }
........
  },
}
Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    config.ssh.insert_key = false
      config.vm.define boxname do |box1|
          box1.vm.box = boxconfig[:box_name]
          box1.vm.host_name = boxname.to_s
          #box.vm.network "forwarded_port", guest: 3260, host: 3260+offset
          box1.vm.network "private_network", ip: boxconfig[:ip_addr]
          box1.vm.provider :virtualbox do |vb|
                      vb.customize ["modifyvm", :id, "--nictype1", "Am79C973"]
	    vb.customize ["modifyvm", :id, "--nictype2", "Am79C973"]
		vb.customize ["modifyvm", :id, "--memory", "1024"]
                  needsController = false
          boxconfig[:disks].each do |dname, dconf|
              unless File.exist?(dconf[:dfile])
            vb.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size]]
                                needsController =  true
                          end
          end
                  if needsController == true
                     vb.customize ["storagectl", :id, "--name", "SATA", "--add", "sata" ]
                     boxconfig[:disks].each do |dname, dconf|
                         vb.customize ['storageattach', :id,  '--storagectl', 'SATA', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium', dconf[:dfile]]
                     end
                  end
          end
		box1.vm.provision :"shell", path: "script.sh"
		end
      end
end
```

после создания машины выполняется скрипт 
который собирает RAID1 из 3 дисков и записывает данные рейда в конфиг файл для автоподключения при 
перезагрузке:

```
#!/bin/bash
yum install -y mdadm
yes|mdadm --create --verbose /dev/md0 -l 1 -n 3 /dev/sd{b,c,d}
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
yes|mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

```

Выполняем команду:
```
root@Proffff:~/otus/lesson1# vagrant up
```
Ожидаем пару минут загрузки системы
