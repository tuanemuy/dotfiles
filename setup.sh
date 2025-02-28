#!/bin/bash

ln -sfn ${PWD}/home-manager ${HOME}/.config/home-manager
ln -sfn ${PWD}/scripts ${HOME}/.scripts

home-manager switch
