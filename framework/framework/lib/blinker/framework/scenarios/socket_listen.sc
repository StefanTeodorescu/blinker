raise 'The socket_listen scenario requires a Rake task named \'executable\'' unless Rake.application[:executable]

executable = Rake.application[:executable].sources.first
raise 'The Rake task \'executable\' must depend on the executable that is to be used' unless executable

unique = BlinkerVars.challenge_id
name = "blinker-challenge-#{unique}"
BlinkerVars.listen_port = random_number 49152..65535

task :handout => executable
task :deploy => "#{name}.deb"

task "opt/#{name}/#{executable}" => executable do
  FileUtils.mkdir_p "opt/#{name}"
  FileUtils.cp executable, "opt/#{name}/#{executable}"
end

generated_file "opt/#{name}/flag" do
  puts random_flag
end

generated_file "opt/#{name}/start.sh" do
  puts '#!/bin/sh'
  puts "/opt/#{name}/#{executable} #{BlinkerVars.executable_args||""}"
end

generated_file "lib/systemd/system/#{name}.service" do
  puts <<EOF
[Unit]
Description=Blinker Challenge #{unique}

[Service]
ExecStart=/bin/sh /opt/#{name}/start.sh
WorkingDirectory=/opt/#{name}/
KillMode=process
Restart=always
RestartSec=1
StartLimitInterval=1
StartLimitBurst=2
User=challenge
Group=nogroup

[Install]
WantedBy=multi-user.target
Alias=#{name}.service
EOF
end

deb_name name
deb_user 'challenge'
deb_group 'nogroup'
deb_preinst <<EOF
#!/bin/sh
adduser --system challenge
EOF
deb_postinst <<EOF
#!/bin/sh
systemctl enable #{name}.service
systemctl start #{name}.service
EOF

deb_archive "#{name}.deb" => ["opt/#{name}/#{executable}", "opt/#{name}/flag", "opt/#{name}/start.sh", "lib/systemd/system/#{name}.service"]
