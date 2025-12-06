#!/bin/bash

ln -sfn ${PWD}/home-manager/home.nix ${HOME}/.config/home-manager/home.nix
ln -sfn ${PWD}/home-manager/programs ${HOME}/.config/home-manager/programs
ln -sfn ${PWD}/home-manager/workarounds ${HOME}/.config/home-manager/workarounds

home-manager switch --impure
