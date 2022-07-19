touch ~/boot_flag
echo "Cold rebooting in 10 seconds..."
sleep 10
sudo -u geniuser perl /local/repository/cold-reboot.pl
