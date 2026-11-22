#!/bin/bash
# Test Absynth OS on Google Cloud. Run in Google Cloud Shell (console.cloud.google.com, the >_ button).
#
# How it works: a Debian VM with nested virtualization runs the real Fedora Kinoite installer in QEMU.
# You install Kinoite inside it and rebase to Absynth OS exactly as on a real PC. The desktop is shown
# in your browser through Cloud Shell's Web Preview (noVNC), so nothing needs installing on Windows.
#
#   bash gcp-test-vm.sh create    # make the VM (Spot; ~10 min first boot while it downloads the ISO)
#   bash gcp-test-vm.sh view      # open the tunnel, then click Web Preview > Preview on port 8080
#   bash gcp-test-vm.sh stop      # stop when done (a stopped VM only costs disk)
#   bash gcp-test-vm.sh start
#   bash gcp-test-vm.sh delete    # remove it completely
#
# Free-trial accounts allow 8 vCPUs in total. The FOURTHNODE builder uses 8, so stop it first
# (bash gcp-builder.sh stop) or set MACHINE=n2-standard-2.
# What a cloud VM can't test: low-latency audio (no sound card), audio interfaces, MIDI, iLok dongles.
set -euo pipefail
NAME="${NAME:-absynthos-test}"
ZONE="${ZONE:-us-central1-a}"
MACHINE="${MACHINE:-n2-standard-4}"   # 4 vCPU / 16 GB; nested virt needs Intel N2/N1/C2-type machines

startup() { cat <<'STARTUP'
#!/bin/bash
set -e
[ -f /var/lib/absynth-ready ] && { systemctl start absynth-qemu absynth-novnc; exit 0; }
apt-get update && apt-get install -y qemu-system-x86 qemu-utils ovmf novnc websockify curl
mkdir -p /srv/absynth && cd /srv/absynth
BASE=https://download.fedoraproject.org/pub/fedora/linux/releases
VER=$(curl -sL $BASE/ | grep -o 'href="[0-9]\+/"' | grep -o '[0-9]\+' | sort -n | tail -1)
ISO=$(curl -sL $BASE/$VER/Kinoite/x86_64/iso/ | grep -o 'Fedora-Kinoite[^"]*x86_64[^"]*\.iso' | head -1)
curl -L -o kinoite.iso "$BASE/$VER/Kinoite/x86_64/iso/$ISO"
qemu-img create -f qcow2 disk.qcow2 80G
cp /usr/share/OVMF/OVMF_VARS_4M.fd vars.fd
cat > /etc/systemd/system/absynth-qemu.service <<UNIT
[Unit]
Description=Absynth OS test VM
[Service]
WorkingDirectory=/srv/absynth
ExecStart=/usr/bin/qemu-system-x86_64 -enable-kvm -cpu host -smp 3 -m 12G \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,file=/srv/absynth/vars.fd \
  -drive file=/srv/absynth/disk.qcow2,if=virtio -cdrom /srv/absynth/kinoite.iso -boot order=cd \
  -device virtio-vga -device qemu-xhci -device usb-tablet -nic user,model=virtio-net-pci \
  -vnc 127.0.0.1:0
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
cat > /etc/systemd/system/absynth-novnc.service <<UNIT
[Unit]
Description=noVNC for the Absynth OS test VM
[Service]
ExecStart=/usr/bin/websockify --web /usr/share/novnc 127.0.0.1:6080 127.0.0.1:5900
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload && systemctl enable --now absynth-qemu absynth-novnc
touch /var/lib/absynth-ready
STARTUP
}

case "${1:-}" in
create)
  gcloud services enable compute.googleapis.com
  f=$(mktemp); startup > "$f"
  gcloud compute instances create "$NAME" \
    --zone="$ZONE" --machine-type="$MACHINE" --enable-nested-virtualization \
    --provisioning-model=SPOT --instance-termination-action=STOP \
    --image-family=debian-12 --image-project=debian-cloud \
    --boot-disk-size=120GB --boot-disk-type=pd-balanced \
    --metadata-from-file=startup-script="$f"
  echo "Created. Wait ~10 minutes for the ISO download, then: bash $0 view" ;;
view)
  echo "Tunnel open. In Cloud Shell click Web Preview (eye icon) > Preview on port 8080, then open /vnc.html"
  echo "Ctrl+C here closes it."
  gcloud compute ssh "$NAME" --zone="$ZONE" -- -N -L 8080:127.0.0.1:6080 ;;
status) gcloud compute ssh "$NAME" --zone="$ZONE" -- 'ls -lh /srv/absynth; systemctl is-active absynth-qemu absynth-novnc' ;;
start)  gcloud compute instances start "$NAME" --zone="$ZONE" ;;
stop)   gcloud compute instances stop "$NAME" --zone="$ZONE" ;;
delete) gcloud compute instances delete "$NAME" --zone="$ZONE" ;;
*) echo "usage: $0 create|view|status|start|stop|delete"; exit 1 ;;
esac
