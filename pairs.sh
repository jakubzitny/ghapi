#!/bin/bash


E="tmux send-keys Enter"

dir="/home/ec2-user"

tmux new-session -d -s stars -n 'checker'
tmux send-keys "cd $dir"; $E

runPart() {
  tmux new-window -t stars -n $1
  tmux send-keys "cd $dir"; $E
  tmux send-keys "./starget.sh $1 $2"; $E
}

runPart jsonly_idurls_ba key1
runPart jsonly_idurls_bb key2
runPart jsonly_idurls_bc key3
runPart jsonly_idurls_bd key4
