# CURRENTLY WORK IN PROGRESS TO CREATE A SDDM THEME

# Install eucalyptus-drop a base
# See: https://gitlab.com/Matt.Jolly/sddm-eucalyptus-drop/
git clone https://gitlab.com/Matt.Jolly/sddm-eucalyptus-drop.git
sudo mv sddm-eucalyptus-drop /usr/share/sddm/themes/eucalyptus-drop

# In the [Theme] section simply add the themes name: Current=eucalyptus-drop
# Copy from /usr/lib/sddm/sddm.conf.d/default.conf
/etc/sddm.conf.d/sddm.conf

# Test the theme
sddm-greeter --test-mode --theme /usr/share/sddm/themes/eucalyptus-drop
