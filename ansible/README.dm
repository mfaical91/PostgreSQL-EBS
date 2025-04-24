#Restaurer un snapshot EBS
ansible-playbook restore.yml -e snapshot_id=snap-0123456789abcdef

# Automatiser les backups
setup-cron.sh
