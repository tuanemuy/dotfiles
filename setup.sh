#!/bin/bash

mkdir -p ${HOME}/.config
ln -sfn ${PWD}/home-manager ${HOME}/.config/home-manager

home-manager switch --impure
