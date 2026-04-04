#!/bin/bash

mkdir -p ${HOME}/.config
ln -sfn ${PWD}/home-manager ${HOME}/.config/home-manager

nix --extra-experimental-features 'nix-command flakes' flake update --flake ~/.config/home-manager
sudo -H nix --extra-experimental-features 'nix-command flakes' run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/home-manager
