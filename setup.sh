#!/bin/bash

ln -sfn ${PWD}/home-manager ${HOME}/.config/home-manager
ln -sfn ${PWD}/tools ${HOME}/.tools

home-manager switch
