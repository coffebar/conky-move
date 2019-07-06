# Conky auto move

Script changes [conky](https://github.com/brndnmtthws/conky) position, depending on window positions on the selected workspace. 

This makes conky visible when possible.

[wmctrl](https://github.com/geekless/wmctrl) is required. Tested on xfce4.

## Install

### 1. Clone this repo or just download file *move.sh*
```
cd $HOME
git clone git@github.com:Hukuta/conky-move.git
```

### 2. Specify the desired conky positions
Run conky. If your *.conkyrc* file is not in "$HOME/.conkyrc" path, you need to set it's location in the top of *move.sh* (CONKY_CONFIG_FILE variable).

In the *.conkyrc* find a line like this:

```gap_x=auto,```

Change it to ```gap_x=0,```, where "0" is a position where conky is on the most desired position. You can experiment with positive or negative values.

When saving a file .conkyrc, conky will appear in a new place. When you find the perfect place for conky, run this command:

```bash $HOME/conky-move/move.sh add```

This will create a file $HOME/conky-move/gap_x 

Then you need to change gap_x value in your .conkyrc again. To put conky on the other side of the monitor, or to another monitor.
After each finding good position, run ```bash $HOME/conky-move/move.sh add``` again. Recommended to use 2-6 positions depending on count and size of monitors.

### 3. Put script to system startup after conky start

After conky starts, use this command:

```bash $HOME/conky-move/move.sh auto & disown```

It will check window positions every 60 seconds. You can change this interval in the move.sh script, but not recommended to use very small value, because it will lead to a significant CPU load.

This is an example of a startup script:

```
#!/usr/bin/env bash

## Wait 10 seconds
sleep 10

## Run conky
conky -d -c "$HOME/.conkyrc"
## conky auto move
bash $HOME/conky-move/move.sh auto & disown
```
