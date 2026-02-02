#!/bin/bash

ln -sfn ${PWD}/home-manager ${HOME}/.config

sudo -H nix --extra-experimental-features 'nix-command flakes' run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/home-manager
