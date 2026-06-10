#!/bin/bash
# Filename：service.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-04-16
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
systemctl --user enable dsearch.service
systemctl --user enable mpDris2.service
systemctl --user enable mpd.service
systemctl --user enable dms.service
systemctl --user enable foot-server.service
systemctl --user daemon-reload


sudo systemctl enable --now power-profiles-daemon.service
sudo systemctl start power-profiles-daemon.service --now
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --permanent --add-service=ssh
sudo systemctl start --now  sshd.service
sudo systemctl enable sshd.service

sudo firewall-cmd --reload
sudo systemctl daemon-reload
