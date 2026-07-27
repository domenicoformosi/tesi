ls /usr/local/src/hostap/.git >/dev/null 2>&1 || git clone --depth 1 --branch hostap_2_11 https://w1.fi/hostap.git /usr/local/src/hostap

cat > /usr/local/src/hostap/hostapd/.config <<'EOF'
CONFIG_DRIVER_NL80211=y
CONFIG_LIBNL32=y
CONFIG_CTRL_IFACE=y
CONFIG_CTRL_IFACE_UNIX=y
CONFIG_IEEE80211N=y
CONFIG_IEEE80211AC=y
CONFIG_IEEE80211AX=y
CONFIG_IEEE80211BE=y
CONFIG_SAE=y
CONFIG_IEEE80211W=y
CONFIG_ACS=y
EOF

make -C /usr/local/src/hostap/hostapd -j"$(nproc)"
install -m 0755 /usr/local/src/hostap/hostapd/hostapd /usr/local/sbin/hostapd
install -m 0755 /usr/local/src/hostap/hostapd/hostapd_cli /usr/local/sbin/hostapd_cli

cat > /usr/local/src/hostap/wpa_supplicant/.config <<'EOF'
CONFIG_DRIVER_NL80211=y
CONFIG_LIBNL32=y
CONFIG_CTRL_IFACE=y
CONFIG_CTRL_IFACE_UNIX=y
CONFIG_SAE=y
CONFIG_IEEE80211W=y
CONFIG_BACKEND=file
EOF

make -C /usr/local/src/hostap/wpa_supplicant -j"$(nproc)"
install -m 0755 /usr/local/src/hostap/wpa_supplicant/wpa_supplicant /usr/local/sbin/wpa_supplicant
install -m 0755 /usr/local/src/hostap/wpa_supplicant/wpa_cli /usr/local/sbin/wpa_cli